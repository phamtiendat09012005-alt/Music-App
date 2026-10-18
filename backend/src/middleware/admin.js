const admin = (req, res, next) => {
  // Kiểm tra user (đã được tìm thấy ở bước auth.js trước đó) có role là 'admin' không
  if (req.user && req.user.role === 'admin') {
    next(); // Là admin -> cho phép đi tiếp
  } else {
    return res.status(403).json({ message: 'Chỉ Admin mới có quyền thực hiện thao tác này' });
  }
};

module.exports = admin;