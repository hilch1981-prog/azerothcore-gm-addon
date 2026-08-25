(function () {
  var menuButton = document.getElementById('menuButton');
  var siteNav = document.getElementById('siteNav');
  var copyPath = document.getElementById('copyPath');
  var copyMessage = document.getElementById('copyMessage');
  var installPath = 'Interface/AddOns/AzerothAdmin/AzerothAdmin.toc';

  if (menuButton && siteNav) {
    menuButton.onclick = function () {
      var isOpen = siteNav.className.indexOf('open') >= 0;
      if (isOpen) {
        siteNav.className = siteNav.className.replace(/\s*open/g, '');
      } else {
        siteNav.className += ' open';
      }
      menuButton.setAttribute('aria-expanded', isOpen ? 'false' : 'true');
    };

    var navLinks = siteNav.getElementsByTagName('a');
    for (var i = 0; i < navLinks.length; i++) {
      navLinks[i].onclick = function () {
        siteNav.className = siteNav.className.replace(/\s*open/g, '');
        menuButton.setAttribute('aria-expanded', 'false');
      };
    }
  }

  function showCopyMessage(message) {
    if (!copyMessage) {
      return;
    }
    copyMessage.innerHTML = message;
    window.setTimeout(function () {
      copyMessage.innerHTML = '';
    }, 1800);
  }

  if (copyPath) {
    copyPath.onclick = function () {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(installPath).then(function () {
          showCopyMessage('경로를 복사했습니다.');
        }, function () {
          showCopyMessage('복사하지 못했습니다. 경로를 직접 선택해 주세요.');
        });
        return;
      }

      var temp = document.createElement('textarea');
      temp.value = installPath;
      temp.setAttribute('readonly', 'readonly');
      temp.style.position = 'absolute';
      temp.style.left = '-9999px';
      document.body.appendChild(temp);
      temp.select();

      try {
        document.execCommand('copy');
        showCopyMessage('경로를 복사했습니다.');
      } catch (e) {
        showCopyMessage('복사하지 못했습니다. 경로를 직접 선택해 주세요.');
      }

      document.body.removeChild(temp);
    };
  }
}());
