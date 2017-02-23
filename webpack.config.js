var webpack = require('webpack')
var StringReplacePlugin = require('string-replace-webpack-plugin')

module.exports = {
  entry: './Blockchain/js/wallet-ios.js',
  output: {
    path: './Blockchain/js/',
    filename: 'bundle.js',
    library: 'MyWalletPhone',
    libraryTarget: 'var'
  },
  resolve: {
    extensions: ['.js', '.json'],
    modules: [
      'node_modules',
      'Submodules'
    ]
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: [
              ['es2015', { modules: false }]
            ],
            plugins: ['transform-object-assign']
          }
        }
      },
      {
        test: /bip39\/index.js$/,
        loader: StringReplacePlugin.replace({
          replacements: [{
            pattern: /validateMnemonic: validateMnemonic/,
            replacement: function (match) { return match + ',\nsalt: salt' }
          }]
        })
      }
    ]
  },
  plugins: [
    new webpack.DefinePlugin({
      'navigator': `({userAgent:''})`
    }),
    new webpack.IgnorePlugin(/^vertx$/),
    new StringReplacePlugin()
  ]
}
