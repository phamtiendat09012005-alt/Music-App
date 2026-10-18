const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const auth = require('../middleware/auth');

// Toàn bộ các thao tác này đều yêu cầu đăng nhập
router.use(auth);

router.post('/favorites/:songId', userController.toggleFavorite);
router.get('/favorites', userController.getFavorites);

module.exports = router;

