var express = require('express');
var router = express.Router();

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', { title: 'Express' });
});
router.get('/cgv', function(req, res, next) {
  res.render('cgv', { title: 'toto' });
});
router.get('/cgu', function(req, res, next) {
  res.render('cgu', { title: 'iti' });
});

module.exports = router;
