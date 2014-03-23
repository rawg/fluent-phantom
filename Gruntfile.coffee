

module.exports = (grunt) ->
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-mocha-test'

    grunt.initConfig
        coffee:
            compile:
                files:
                    'index.js': 'src/main/coffee/**/*.coffee'
                options:
                    sourceMap: true

            compileTests:
                expand: true,
                flatten: true,
                cwd: 'src/test/coffee',
                src: ['*.coffee'],
                dest: 'test',
                ext: '.js'

        mochaTest:
            test:
                options:
                    reporter: 'spec'
                    timeout: 30000
                    require: ['should']
                src: ['test/**/*.js']

        watch:
            files: ['src/main/coffee/**/*.coffee', 'src/test/coffee/**/*.coffee']
            tasks: ['coffee:compile', 'coffee:compileTests', 'mochaTest:test']

    grunt.registerTask 'default', ['coffee', 'mochaTest']

