

window.onload = function () {
	var headlines = 0, 
		tickers = 0,
		trailing = 0;

	function addHeadline() {
		document.querySelector('#headlines').innerHTML += "<li>Headline " + ++headlines + "</li>";
	}

	function addTrailing() {
		document.querySelector('#trailing').innerHTML += "<li>Trailing " + ++trailing + "</li>";
	}
	
	function addTicker() {
		document.querySelector('#ticker').innerHTML += "<li>Ticker " + ++tickers + "</li>";
	}

	setInterval(addTicker, 1000);

	setTimeout(function () {
		for (var i = 1; i <= 10; i++) {
			addHeadline()
		}
	}, 1000);

	for (var i = 1; i <= 5; i++) {
		setTimeout(addTrailing, 500 * i);
	}

}

