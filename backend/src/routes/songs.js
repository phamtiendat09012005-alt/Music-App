const express = require('express');
const router = express.Router();
const songController = require('../controllers/songController');
const auth = require('../middleware/auth');
const admin = require('../middleware/admin');
const upload = require('../middleware/upload');

// Các route công khai (App Flutter và Web Admin đều xem được)
router.get('/', songController.getSongs);
router.get('/:id', songController.getSongById);
router.post('/:id/play', songController.incrementPlayCount);

// Các route yêu cầu quyền Admin và upload file (dùng cho Web Admin theo Mục 8)
router.post(
  '/',
  auth,
  admin,
  upload.fields([
    { name: 'audio', maxCount: 1 },
    { name: 'instrumental', maxCount: 1 },
    { name: 'cover', maxCount: 1 },
    { name: 'lyrics', maxCount: 1 },
  ]),
  songController.createSong
);

router.put(
  '/:id',
  auth,
  admin,
  upload.fields([
    { name: 'audio', maxCount: 1 },
    { name: 'instrumental', maxCount: 1 },
    { name: 'cover', maxCount: 1 },
    { name: 'lyrics', maxCount: 1 },
  ]),
  songController.updateSong
);

router.put('/:id/lyrics', auth, admin, songController.updateSongLyrics);
router.delete('/:id', auth, admin, songController.deleteSong);

module.exports = router;