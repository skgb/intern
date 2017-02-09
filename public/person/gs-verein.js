(function () {
	// IE 8 isn't officially supported, but this should make it work
	if (! document.getElementsByClassName) {
		document.getElementsByClassName = function(className) {
			return this.querySelectorAll("."+className);
		};
//		Element.prototype.getElementsByClassName = document.getElementsByClassName;
	}
	var onloadOld = window.onload;
	
	// set up tabs
	window.onload = function gsvTabs () {
		var tabClick = function () {
			this.parentNode.style.display = "none";
			document.getElementById("gsv"+this.id.substr(7,1)).style.display = "block";
		};
		
		// hide initially inactive tabs
		var initialTab = Math.max(1, Math.min(5, parseInt( window.location.hash.substr(1) )));
		if (isNaN(initialTab)) { initialTab = 1; }
		for (var i = 1; i <= 5; i++) {
			if (i != initialTab) {
				document.getElementById("gsv"+i).style.display = "none";
			}
			
			// set button handlers
			for (var j = 1; j <= 5; j++) {
				document.getElementById("gsv"+i+"tab"+j).onclick = tabClick;
			}
		}
		var closeButtons = document.getElementsByClassName("close");
		for (var i = 0; i < closeButtons.length; i++) {
			closeButtons[i].onclick = function () {
				if (window.location.protocol == "file:") { return false; }
				if (history.length > 1) { history.back(); }
				else { document.location.href = "./"; }
				return false;  // cancel event in case this is an <a> element
			};
		}
		
		// extract fixed fee
		var feeOptions = document.getElementById("Satz").options;
		for (var i = 0; i < feeOptions.length; i++) {
			if (! feeOptions.item(i).selected) { continue; }
			var match = feeOptions.item(i).textContent.match(/\[(.*)\]$/);
			if (match) {
				document.getElementById("SatzInfo").innerHTML = "(z.Zt. "+match[1]+" / Jahr)";
			}
			break;
		}
		
		// make data easier readable, but still read-only
		var popupMenus = document.getElementsByTagName("SELECT");
		for (var i = 0; i < popupMenus.length; i++) {
			popupMenus[i].setAttribute("data-value", popupMenus[i].value);
			popupMenus[i].onchange = function () {
				this.value = this.getAttribute("data-value");
			};
			popupMenus[i].disabled = false;
		}
		var inputFields = document.getElementsByTagName("INPUT");
		for (var i = 0; i < inputFields.length; i++) {
			if (inputFields[i].getAttribute("type") != "checkbox") { continue; }
			inputFields[i].setAttribute("data-value", inputFields[i].checked);
			inputFields[i].onclick = function () {
				this.checked = this.getAttribute("data-value") == "true";
			};
			inputFields[i].disabled = false;
		}
	};
	
	if (document.addEventListener) {
		document.addEventListener('DOMContentLoaded', window.onload, false);
		window.onload = onloadOld;
	}
})();
