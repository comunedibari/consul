$(document).ready(function () {
  preselectTypologyPills();
  init();
});

function init() {
  let typologySubmitFormButton = document.getElementById('typology_submit_form_button');
  let cancelFiltersFormButton = document.getElementById('cancel_form_button');
  let typologyFiltersForm = document.getElementById('advanced_search_form');

  let typologyPills = document.getElementsByClassName('typology-pill');

  cancelFiltersFormButton.addEventListener('click', () => {
    let paramsElement = document.getElementById('typology_id');

    if (paramsElement.value !== '') {
      paramsElement.value = '';
      typologyFiltersForm.submit();
    }
  })

  typologySubmitFormButton.addEventListener('click', () => {
    typologyFiltersForm.submit();
  })

  Object.keys(typologyPills).forEach(
    key => {
      typologyPills.item(parseInt(key)).addEventListener('click', onTypologyPillClicked);
    }
  )
}

function toggleSelectedClass(id) {
  let element = document.querySelector('a[data-typologyid="' + id + '"]');
  if (!element.classList.contains("selected")) {
    element.classList.add('selected');
  } else {
    element.classList.remove('selected');
  }
}

function toggleTypologyIdParams(typologyId) {
  let paramsElement = document.getElementById('typology_id');
  let arrayId = [];

  if (paramsElement.value !== '') {
    arrayId = paramsElement.value.split(',');
  }

  if (arrayId.includes(typologyId)) {
    // Se l'id è già presente, lo elimino
    let position = arrayId.indexOf(typologyId);
    arrayId.splice(position, 1);
    paramsElement.value = arrayId.join(',');
  } else {
    // Se l'id non è presente, lo aggiungo
    arrayId.push(typologyId);
    paramsElement.value = arrayId.join(',');
  }
}

function onTypologyPillClicked(event) {
  event.preventDefault();
  let id = event.target.dataset.typologyid;
  selectTypologyPill(id);
}

function selectTypologyPill(id) {
  toggleSelectedClass(id);
  toggleTypologyIdParams(id);
}

function preselectTypologyPills() {
  let ids = extractTypologyIdsFromGet();

  if (ids !== '') {
    let ids_array = ids.split(',');

    ids_array.forEach(
      id => {
        selectTypologyPill(id);
      }
    )
  }
}

function extractTypologyIdsFromGet() {
  let parts = window.location.search.substr(1).split('&');
  let returnIds = '';

  parts.forEach(
    part => {
      let temp = part.split('=');
      let decodedKey = decodeURIComponent(temp[0]);

      if (decodedKey == "typology[id]") {
        returnIds = decodeURIComponent(temp[1]);
      }
    }
  )

  return returnIds;
}
