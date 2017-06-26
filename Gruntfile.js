module.exports = function (grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    replace: {
      // monkey patch deps
      bitcoinjs: {
        // comment out value validation in fromBuffer to speed up node
        // creation from cached xpub/xpriv values
        src: ['node_modules/bitcoinjs-lib/src/hdnode.js'],
        overwrite: true,
        replacements: [{
          from: /\n{4}curve\.validate\(Q\)/g,
          to: '\n    // curve.validate(Q)'
        }]
      }
    },

    browserify: {
      options: {
        debug: false,
        browserifyOptions: {
          standalone: 'Blockchain',
          transform: [
            ['babelify', {
              presets: ['es2015'],
              plugins: ['transform-object-assign'],
              global: true,
              ignore: [
                '/src/blockchain-socket.js',
                '/src/ws-browser.js'
              ]
            }]
          ]
        }
      },
      build: {
        src: ['src/index.js'],
        dest: 'dist/my-wallet.js'
      }
    }
  });

  grunt.loadNpmTasks('grunt-browserify');
  grunt.loadNpmTasks('grunt-text-replace');

  grunt.registerTask('build', [
    'replace:bitcoinjs',
    'browserify:build',
  ]);
};
