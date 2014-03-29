

module.exports = (grunt) ->
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-mocha-test'

    grunt.initConfig
        mochaTest:
            test:
                options:
                    reporter: 'spec'
                    timeout: 30000
                    require: ['should', 'coffee-script/register']
                src: ['test/**/*.coffee']

        watch:
            files: ['lib/**/*.coffee', 'test/**/*.coffee'] #src/main/coffee/**/*.coffee', 'src/test/coffee/**/*.coffee']
            tasks: ['mochaTest:test']

    grunt.registerTask 'default', ['mochaTest']
    grunt.registerTask 'test', ['mochaTest']

