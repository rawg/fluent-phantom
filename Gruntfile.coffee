

module.exports = (grunt) ->
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-mocha-test'
    grunt.loadNpmTasks 'grunt-express'
    grunt.loadNpmTasks 'grunt-docco'

    grunt.initConfig
        coffee:
            compile:
                files:
                    'index.js': 'index.coffee'
            
        mochaTest:
            test:
                options:
                    reporter: 'spec'
                    timeout: 30000
                    require: ['should', 'coffee-script/register']
                #src: ['test/**/*.coffee']
                src: ['test/request-test.coffee', 'test/request-builder-test.coffee']

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
            files: ['index.coffee', 'test/**/*.coffee']
            tasks: ['coffee:compile', 'express:server', 'mochaTest:test']

    grunt.registerTask 'default', ['coffee', 'express', 'mochaTest']
    grunt.registerTask 'server', ['express', 'express-keepalive']
    grunt.registerTask 'test', ['express', 'mochaTest']
    grunt.registerTask 'docs', ['docco']
    grunt.registerTask 'compile', ['coffee']

