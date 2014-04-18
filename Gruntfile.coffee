

module.exports = (grunt) ->
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-mocha-test'
    grunt.loadNpmTasks 'grunt-express'
    grunt.loadNpmTasks 'grunt-docco'
    grunt.loadNpmTasks 'grunt-markdown'

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
                src: ['test/request-test.coffee', 'test/request-builder-test.coffee', 'test/functional-test.coffee']

        express:
            server:
                options:
                    port: 3050
                    bases: 'test/resources'
        
        docco:
            debug:
                src: ['index.coffee']
                options:
                    output: 'docs/'

        markdown:
            all:
                files:
                    'docs/readme.html': 'README.md'

        watch:
            files: ['index.coffee', 'test/**/*.coffee', 'test/resources/index.html', 'test/resources/javascripts/test.js']
            tasks: ['coffee:compile', 'express:server', 'mochaTest:test']

    grunt.registerTask 'default', ['express', 'mochaTest', 'coffee', 'docco', 'markdown']
    grunt.registerTask 'server', ['express', 'express-keepalive']
    grunt.registerTask 'test', ['express', 'mochaTest']
    grunt.registerTask 'docs', ['docco', 'markdown']
    grunt.registerTask 'compile', ['coffee']
    grunt.registerTask 'dist', ['coffee', 'docco', 'markdown']

