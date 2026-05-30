const container = document.getElementById('container');

window.addEventListener('message', function (event) {
    const data = event.data;
    if (data.action === 'render') {
        container.innerHTML = data.html || '';
    }
});
