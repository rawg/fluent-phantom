

module.exports = (grunt) ->
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-mocha-test'
    grunt.loadNpmTasks 'grunt-express'
    grunt.loadNpmTasks 'grunt-docco'


    grunt.initConfig
        mochaTest:
            test:
                options:
                    reporter: 'spec'
                    timeout: 30000
                    require: ['should', 'coffee-script/register']
                src: ['test/**/*.coffee']

        express:
            server:
                options:
                    port: 3050
                    bases: 'test/resources'
        
        docco:
            debug:
                src: ['lib/**/*.coffee']
                options:
                    output: 'docs/'
        watch:
            files: ['lib/**/*.coffee', 'test/**/*.coffee']
            tasks: ['express:server', 'mochaTest:test']

    grunt.registerTask 'default', ['express', 'mochaTest']
    grunt.registerTask 'server', ['express', 'express-keepalive']
    grunt.registerTask 'docs', ['docco']

