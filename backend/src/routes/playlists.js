const express = require('express');
const router = express.Router();
const playlistController = require('../controllers/playlistController');

router.get('/', playlistController.getPlaylists);
router.post('/', playlistController.createPlaylist);
router.delete('/:id', playlistController.deletePlaylist);

module.exports = router;

