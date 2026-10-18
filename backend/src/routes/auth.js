const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const auth = require('../middleware/auth');

// Các endpoint không cần đăng nhập
router.post('/register', authController.register);
router.post('/login', authController.login);

// Endpoint cần đăng nhập (có middleware auth đứng chắn ở giữa)
router.get('/me', auth, authController.getMe);

module.exports = router;