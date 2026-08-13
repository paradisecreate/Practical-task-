pipelineJob('practical-task-pipeline') {

    triggers {
        // GitHub webhook
        githubPush()

        // Fallback while webhook is not configured yet
        scm('H/2 * * * *')
    }

    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/paradisecreate/Practical-task-.git')
                    }

                    branch('*/terraform-automation')
                }
            }

            scriptPath('jenkins/Jenkinsfile')
        }
    }
}