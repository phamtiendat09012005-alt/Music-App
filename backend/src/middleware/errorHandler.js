const errorHandler = (err, req, res, next) => {
  console.error(err.stack);
  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({
    message: err.message || 'Lỗi máy chủ nội bộ',
  });
};

module.exports = errorHandler;