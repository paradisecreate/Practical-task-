const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execFile } = require('child_process');

const PORT = 3000;

const REPO = __dirname;
const INDEX = path.join(REPO, 'website', 'indexKZ.html');

const GIT_BRANCH = process.env.GIT_BRANCH || 'main';

const BOARD_SECRET = process.env.BOARD_SECRET;

function secretMatches(provided) {
    if (typeof provided !== 'string' || provided.length === 0) {
        return false;
    }

    const a = Buffer.from(provided);
    const b = Buffer.from(BOARD_SECRET);

    if (a.length !== b.length) {
        return false;
    }

    return crypto.timingSafeEqual(a, b);
}

function escapeHtml(s) {
    return String(s)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function git(args) {
    return new Promise((resolve, reject) => {
        execFile(
            'git',
            ['-C', REPO, ...args],
            {
                timeout: 20000,
                env: {
                    ...process.env,
                    GIT_TERMINAL_PROMPT: '0'
                }
            },
            (err, stdout, stderr) => {
                if (err) {
                    reject(new Error(stderr || err.message));
                } else {
                    resolve(stdout.trim());
                }
            }
        );
    });
}

function addCard(requirement) {
    const html = fs.readFileSync(INDEX, 'utf8');
    const safe = escapeHtml(requirement);

    const card =
`                    <div class="ticket">
                        <span class="ticket-tag">Requirement</span>
                        <p>${safe}</p>
                    </div>
                    <!-- new-cards -->`;

    const marker = '<!-- new-cards -->';

    if (!html.includes(marker)) {
        throw new Error(
            'Could not find the board marker in indexKZ.html.'
        );
    }

    const updated = html.replace(marker, card);

    fs.writeFileSync(INDEX, updated, 'utf8');
}

function setCors(res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader(
        'Access-Control-Allow-Methods',
        'POST, OPTIONS'
    );
    res.setHeader(
        'Access-Control-Allow-Headers',
        'Content-Type, X-Board-Secret'
    );
}

const server = http.createServer((req, res) => {

    setCors(res);

    if (req.method === 'OPTIONS') {
        res.writeHead(204).end();
        return;
    }

    if (
        req.method === 'GET' &&
        req.url === '/health'
    ) {
        res.writeHead(
            200,
            { 'Content-Type': 'application/json' }
        );

        res.end(
            JSON.stringify({
                ok: true,
                status: 'up',
                branch: GIT_BRANCH
            })
        );

        return;
    }

    if (
        req.method === 'POST' &&
        req.url === '/api/requirement'
    ) {

        if (
            !secretMatches(
                req.headers['x-board-secret']
            )
        ) {
            res.writeHead(
                401,
                { 'Content-Type': 'application/json' }
            );

            res.end(
                JSON.stringify({
                    ok: false,
                    error:
                        'Unauthorized: wrong or missing passphrase.'
                })
            );

            return;
        }

        let body = '';

        req.on('data', chunk => {
            body += chunk;

            if (body.length > 5000) {
                req.destroy();
            }
        });

        req.on('end', async () => {

            try {

                const {
                    requirement
                } = JSON.parse(body || '{}');

                if (
                    !requirement ||
                    typeof requirement !== 'string' ||
                    requirement.trim().length === 0
                ) {

                    res.writeHead(
                        400,
                        {
                            'Content-Type':
                                'application/json'
                        }
                    );

                    res.end(
                        JSON.stringify({
                            ok: false,
                            error: 'Requirement is empty.'
                        })
                    );

                    return;
                }

                const text =
                    requirement
                        .trim()
                        .slice(0, 500);

                addCard(text);

                await git([
                    'add',
                    'website/indexKZ.html'
                ]);

                try {
                    await git([
                        'commit',
                        '-m',
                        'Add requirement from board'
                    ]);
                } catch (commitErr) {
                    if (
                        !/nothing to commit/i.test(
                            commitErr.message
                        )
                    ) {
                        throw commitErr;
                    }
                }

                await git([
                    'pull',
                    '--rebase',
                    'origin',
                    GIT_BRANCH
                ]);

                await git([
                    'push',
                    'origin',
                    `HEAD:${GIT_BRANCH}`
                ]);

                res.writeHead(
                    200,
                    {
                        'Content-Type':
                            'application/json'
                    }
                );

                res.end(
                    JSON.stringify({
                        ok: true,
                        message:
                            `Pushed to ${GIT_BRANCH}. Jenkins will deploy it shortly.`
                    })
                );

            } catch (e) {

                if (!res.headersSent) {

                    res.writeHead(
                        500,
                        {
                            'Content-Type':
                                'application/json'
                        }
                    );

                    res.end(
                        JSON.stringify({
                            ok: false,
                            error: e.message
                        })
                    );
                }
            }
        });

        return;
    }

    res.writeHead(404).end('Not found');
});

if (
    !BOARD_SECRET ||
    BOARD_SECRET.length < 8
) {
    console.error(
        'Refusing to start: BOARD_SECRET must be at least 8 characters.'
    );

    process.exit(1);
}

process.on(
    'uncaughtException',
    err => {
        console.error(
            'Uncaught exception:',
            err
        );
    }
);

process.on(
    'unhandledRejection',
    reason => {
        console.error(
            'Unhandled rejection:',
            reason
        );
    }
);

server.on(
    'clientError',
    (err, socket) => {
        if (socket.writable) {
            socket.end(
                'HTTP/1.1 400 Bad Request\r\n\r\n'
            );
        }
    }
);

server.on(
    'error',
    err => {
        console.error(
            'Server error:',
            err.message
        );
    }
);

server.listen(
    PORT,
    '0.0.0.0',
    () => {
        console.log(
            `Requirements Board backend running on port ${PORT}`
        );

        console.log(
            `Git branch: ${GIT_BRANCH}`
        );

        console.log(
            `Health: http://localhost:${PORT}/health`
        );
    }
);