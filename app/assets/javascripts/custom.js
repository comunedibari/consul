// Overrides and adds customized javascripts in this file
// Read more on documentation:
// * English: https://github.com/consul/consul/blob/master/CUSTOMIZE_EN.md#javascript
// * Spanish: https://github.com/consul/consul/blob/master/CUSTOMIZE_ES.md#javascript
//
//

function inputNumberIhibitor(event) {
  let charCode = 0;
  let charTyped = '';

  // Recupero il charCode corretto a seconda di quale campo mi restituisce il browser
  if (event.charCode != null) charCode = event.charCode;
  else if (event.which != null) charCode = event.which;
  else if (event.keyCode != null) charCode = event.keyCode;

  // Permetto l'uso di alt, control e gli input speciali (frecc ecc)
  if (event.altKey || event.ctrlKey || charCode < 28) return true;

  // Controllo che il carattere non sia un carattere speciale
  if (charCode === 0) {
    charTyped = 'SPECIAL KEY';
  } else {
    // Trasformo il codice carattere in stringa
    charTyped = String.fromCharCode(charCode);
  }

  // Se il carattere è una cifra, un punto o un backspace, lascio scrivere
  if (charTyped.match(/[0-9.,]/)) return true;
  // if (charTyped.match(/\d|[\b]|SPECIAL/)) return true;

  // In tutti gli altri casi, restituisco false
  if (event.preventDefault) event.preventDefault();
  event.returnValue = false;
  return false;
}

function scrollIntoRealView(event) {
  let header_wrapper_height = document.getElementsByClassName('it-header-wrapper')[0].scrollHeight;
  let safeMargin = 55;
  let form = document.getElementById(event.target.form.id);
  let invalidElements = form.querySelectorAll(':invalid');
  let firstInvalidElement = invalidElements[0];
  let firstInvalidElementOffsetTop = firstInvalidElement.offsetTop;

  window.scrollTo(0, firstInvalidElementOffsetTop - (header_wrapper_height + safeMargin));
}

function notificationShow(notificationTarget, notificationTimeOut) {

  if ($('#' + notificationTarget).hasClass('dismissable')) {
    //dismissable
    $('#' + notificationTarget).fadeIn(300);
  } else {
    //standard (timeout)
    $('#' + notificationTarget).fadeIn(300);
    if (typeof notificationTimeOut == "number") {
      //timeout set by parameter
      var timeToFade = notificationTimeOut;
    } else {
      //timeout default value 7s
      var timeToFade = 7000;
    }
    //fadeout
    setTimeout(function () {
      $('#' + notificationTarget).fadeOut(100);
    }, timeToFade);
  }
}

//dismissable close button
$('.notification-close').click(function () {
  $(this).closest('.notification').fadeOut(100);
});

// Aggiro bug safari con le grid di Bootstrap 4
if (navigator.userAgent.indexOf('Safari') !== -1 && navigator.userAgent.indexOf('Chrome') === -1) {
  // Siamo su Safari
  let stylesheet = document.styleSheets[1];
  stylesheet.insertRule(".row::before { display: none !important; }");
  stylesheet.insertRule(".row::after { display: none !important; }");
} else {
  // Non siamo su Safari
}

