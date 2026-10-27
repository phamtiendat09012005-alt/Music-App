const express = require('express');
const router = express.Router();
const playlistController = require('../controllers/playlistController');

router.get('/', playlistController.getPlaylists);
router.post('/', playlistController.createPlaylist);
router.post('/:id/songs', playlistController.addSongToPlaylist);
router.delete('/:id/songs/:songId', playlistController.removeSongFromPlaylist);
router.delete('/:id', playlistController.deletePlaylist);

module.exports = router;

