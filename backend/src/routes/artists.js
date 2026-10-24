const express = require('express');
const router = express.Router();
const artistController = require('../controllers/artistController');
const auth = require('../middleware/auth');
const admin = require('../middleware/admin');
const upload = require('../middleware/upload');

// Route công khai: Lấy danh sách nghệ sĩ (Mobile App và Web Admin đều dùng)
router.get('/', artistController.getArtists);

// Route yêu cầu quyền Admin: Cập nhật / Đổi ảnh đại diện của ca sĩ/nghệ sĩ
router.post(
  '/',
  auth,
  admin,
  upload.single('avatar'),
  artistController.createOrUpdateArtist
);

router.put(
  '/:name',
  auth,
  admin,
  upload.single('avatar'),
  artistController.createOrUpdateArtist
);

router.delete('/:id', auth, admin, artistController.deleteArtist);

module.exports = router;

