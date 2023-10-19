module.exports = {
  module: {
    rules: [
      {
        test: /\.less$/i,
        // include: [/node_modules/, /src\/lib/],
        use: ['style-loader', 'css-loader', 'less-loader']
      }
    ]
  }
};
