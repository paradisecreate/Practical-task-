pipelineJob('practical-task-pipeline') {
    triggers {
        githubPush()
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