if (! window.SKGB) { window.SKGB = {}; }


// :BUG: wird ein gerade in der animation befindliches item verschoben, kommt es zu inkonsistenzen zwischen modell und ui


window.config = {
	markWeekDay: 3,  // Wednesday
	summerStart: {month: 2, day: 17+7}, // March 2018
	summerEnd: {month: 9, day: 13-7}  // October 2018
};

// onload:
$(function(){
	// Tabs
	$('#tabs').tabs();
	
	var paramsSource = $('#initdata').get(0).innerHTML;
	eval('window.params = ' + paramsSource);
	var params = window.params;
	var config = window.config;
	var dates = null;
	
	function reset () {
		// create UI controller
		var uiBindings = {
			trashDropTargetNode: $('#members-list')[0],
			memberPrototypesListNode: $('#members-list')[0],
			membersColumnTableHeaderCell: $('TABLE#stegdienst TR:first-child>TH#member-cols')[0],
			tableBody: $('TABLE#stegdienst>TBODY')[0],
			tableHeaderRow: $('TABLE#stegdienst TR:first-child')[0],
			getTableCell: function (row, col) {
				return $( 'TD.member', $('#stegdienst > TBODY > TR')[row] )[col];
			},
			strategyForm: $('#strategy')[0],
			exportData: $('#exportdata')[0],
			importData: $('#importdata')[0],
			warningsArea: $('#warningsarea')[0]
		};
		SKGB.stegdienstController = new SKGB.StegdienstListeInterface(uiBindings);
		SKGB.stegdienstController.resetInterface();
		
		// create data model
		dates = getSuggestionDates(config);
		SKGB.stegdienstListe = new SKGB.StegdienstListe();
		SKGB.stegdienstListe.members = params.members;
		SKGB.stegdienstListe.setDateRange(dates);
		var boardMemberCount = 0;
		var exemptMemberCount = 0;
		for (var i = 0; i < params.members.length; i++) {
			if (params.members[i].board) { boardMemberCount += 1; }
			if (params.members[i].exempt) { exemptMemberCount += 1; }
		}
		var idealModus = Math.max(1, 1 + Math.round(( dates.length * 2 - (params.members.length - exemptMemberCount /*- boardMemberCount*/) ) / ( params.members.length - exemptMemberCount )));
		for (var i = 0; i < params.members.length; i++) {
			/*if (params.members[i].board) { params.members[i].idealCount = idealModus - 1; }
			else*/ if (params.members[i].exempt) { params.members[i].idealCount = 0; }
			else { params.members[i].idealCount = idealModus; }
		}
		SKGB.stegdienstController.liste = SKGB.stegdienstListe;
		
		SKGB.stegdienstController.generatePrototypes();
	}
	
	function newData () {
		SKGB.stegdienstController.createStegdienstDom(dates);
		SKGB.stegdienstController.dataHasChanged();
		$('.overwrite-warning').toggleClass('active', true);  // hide warning until there is something that would be overwritten
		$('form[name="liste-form"]')[0].innerHTML = '';  // only show button until list is populated for the first time; the button helps users to get started, its hiding prevents accidental erasures or the users not finding the strategies pane
		if (window.userIsBoardMember !== false) {
			// this is not meant to be fool-proof -- evil users can easily re-create something closely resembling the club's letterhead anyway
			$('#printbutton')[0].disabled = false;
		}
	}
	
	// set up UI
	$('#strategy input[name="sortkey"]').click(function () {
		$('#strategy input[name="strategy"][value="sorted"]').click();
		var lastnameChecked = $('#strategy input[name="sortkey"][value="lastname"]')[0].checked;
		$('#strategy input[name="descending"]')[0].disabled = lastnameChecked;
		$('#strategy input[name="descending"]')[0].parentNode.className = lastnameChecked ? 'not-implemented' : '';
		if (lastnameChecked) {
			$('#strategy input[name="descending"]')[0].checked = false;
		}
	});
	$('#strategy input[name="descending"]').click(function () {
		$('#strategy input[name="strategy"][value="sorted"]').click();
	});
//	$('#strategy input[name="strategy"]').click(function () {
//		var importChecked = $('#strategy input[name="strategy"][value="import"]')[0].checked;
//		$('#strategy .generate-suggestion-button')[0].value = importChecked ? 'Liste importieren…' : 'Vorschlag erzeugen';
//	});
	$('#strategy input[name="randomiser"]').change(function () {
		$('#strategy input[name="strategy"][value="random"]').click();
		var withChecked = $('#strategy input[name="randomiser"][value="with"]')[0].checked;
		$('#strategy input[name="smart"]')[0].disabled = withChecked;
		$('#strategy input[name="smart"]')[0].parentNode.className = withChecked ? 'not-implemented' : '';
	});
	$('#strategy select[name="basedata"]').change(function () {
		$('#strategy input[name="strategy"][value="base"]').click();
	});
	$('.generate-suggestion-button').click(function () {
		var importChecked = $('#strategy input[name="strategy"][value="import"]')[0].checked;
		if (importChecked) {
			$('#tabs').tabs('select', 6);
			return;
		}
		reset();
		SKGB.stegdienstController.generateSuggestions(dates);
		newData();
	});
	$('.generate-suggestion-button')[1].disabled = false;
	$('.generate-suggestion-button')[2].disabled = false;

	$('#import-form input[name="import"]').click(function () {
		reset();
		SKGB.stegdienstController.importData(dates);
		newData();
	});
	$('#import-form input[name="import"]')[0].disabled = false;
	$('#printbutton').click(function () {
		SKGB.print();
	});
	
// :DEBUG:
//	$('#tabs').tabs('select', 1);
//	reset();
//	SKGB.stegdienstController.generateSuggestions(dates);
//	newData();
});


function getSuggestionDates (config) {
	var today = new Date();
	var year = today.getFullYear() + (today.getMonth() < 8 ? 0 : 1);
//year = 2014; config.summerStart.month = 2; config.summerStart.day = 22+7; config.summerEnd.month = 9; config.summerEnd.day = 25-7;
	var startDate = new Date(year, config.summerStart.month, config.summerStart.day, 12);
	while (startDate.getDay() !== config.markWeekDay) {
		startDate.setDate(startDate.getDate() - 1);
	}
	
	var endDate = new Date(year, config.summerEnd.month, config.summerEnd.day);
	var date = new Date(startDate);
	var weekCount = 0;
	while (date < endDate) {
		date.setDate(date.getDate() + 7);
		weekCount++;
	}
	endDate = new Date(date);
	
	// NB: endDate doesn't currently seem to be used
	return { start: startDate, length: weekCount, end: endDate };
}


// ====================================================

// model
SKGB.StegdienstListe = function () {
	this.data = [];
	this.firstDate = null;
}
SKGB.StegdienstListe.constructor = SKGB.StegdienstListe;

SKGB.StegdienstListe.prototype.members = null;  // params.members


SKGB.StegdienstListe.prototype.setDateRange = function (suggestionDates) {
	if (this.data.length != suggestionDates.length) {
		if (this.firstDate != null) { throw 'Not implemented.'; }
		this.data = new Array(suggestionDates.length);
	}
	this.firstDate = suggestionDates.start;
}


SKGB.StegdienstListe.prototype.assign = function (reference, memberIndex) {
	this.data[reference.row][reference.col] = this.members[memberIndex];
}


SKGB.StegdienstListe.prototype.assignment = function (reference) {
	for (var i = 0; i < this.members.length; i++) {
		if (this.data[reference.row][reference.col] == this.members[i]) {
			return i;
		}
	}
	return -1;
}


SKGB.StegdienstListe.prototype.generateMonteCarloSuggestions = function (members, dates, membersPerDate) {
	var bestScore = -Infinity;
	var worstScore = +Infinity;
	var iterations = 0;
	
	var end = new Date( new Date().valueOf() + 200 );
	do {
		for (var i = 0; i < 10; i++) {
			var liste = new SKGB.StegdienstListe();
			liste.members = members;  // what exactly does this do? do we even need it?
//			liste.setDateRange(dates);  // what exactly does this do? do we even need it?
			liste.generateShuffledSuggestions(members, dates, membersPerDate, true);
			liste.updateCount();
			var warnings = new SKGB.StegdienstListeWarningList(liste);
//			console.log('#' + iterations + ' score: ' + warnings.displayScore());
			if (warnings.score() > bestScore) {
				console.log((bestScore > -Infinity ? 'better ' : '') + 'solution (' + warnings.score() + ') at #' + iterations);
				bestScore = warnings.score();
				for (var j = 0; j < liste.data.length; j++) {
					this.data[j] = liste.data[j];
				}
			}
			if (warnings.score() < worstScore) {
				worstScore = warnings.score();
			}
			iterations += 1;
		}
	} while (new Date() < end);
	
	console.log('iterations: ' + iterations);
	console.log('best score: ' + bestScore);
	console.log('worst score: ' + worstScore);
	this.updateCount();
	var warnings = new SKGB.StegdienstListeWarningList(this);
//	console.log('this score: ' + warnings.score());
}


SKGB.StegdienstListe.prototype.generateShuffledSuggestions = function (members, dates, membersPerDate, smart) {
	
	function swap (array, i, j) {
		var item = array[j];
		array[j] = array[i];
		array[i] = item;
	}
	
	function fisherYatesShuffle (array) {
		for (var i = array.length - 1; i >= 1; i--) {
			var j = parseInt(Math.random() * (i + 1));  // 0 ≤ j ≤ i  :  0 ≤ Math.random() < 1
			swap(array, i, j);
		}
	}
	
	// the strategy: shuffle member list (so as to randomise which members have more dates than others)
	// then assign dates from that list and shuffle again (so as to not have predictable repetition in the Stegdienstliste)
	
	var membersShuffled = members.slice();
	fisherYatesShuffle( membersShuffled );
	
	// :TODO: recode this, basing it upon the individual member's new .idealCount property
	
	var memberAssignees = new Array( dates.length * membersPerDate );
	var j = 0;
	for (var i = 0; i < memberAssignees.length; i++) {
		if (j >= membersShuffled.length) {
			j = 0;  
		}
		while (smart && membersShuffled[j].exempt) {
			j++;  // skip this particular member
			if (j >= membersShuffled.length) {
				j = 0;  
			}
		}
		if (smart && i >= (membersShuffled.length - 2 /*exempt*/) * 2) {
			// prevent board members from being assigned multiple times
			// BUG: infinite loop if all members are board members
			// DEBUG: --> hard-code id 085 to avoid 3 stegdienste
			// DEBUG: --> also hard-code those who had either 3 stegdienste in the previous year or 3 stegdienste in at least two out of the last three years to avoid them this year
			// DEBUG: --> also hard-code new members to avoid 3 stegdienste this year
			while (/*membersShuffled[j].board ||*/ membersShuffled[j].exempt || (i >= membersShuffled.length * 2 /*- 8*/ /*board*/ * 1 - 2 /*exempt*/ * 2 && ( membersShuffled[j].id == 85 || membersShuffled[j].id == 365 || membersShuffled[j].id == 299 || membersShuffled[j].id == 91 || membersShuffled[j].id == 45 || membersShuffled[j].id == 515 ))) {
				j++;  // skip this particular member
				if (j >= membersShuffled.length) {
					j = 0;  
				}
			}
		}
		memberAssignees[i] = membersShuffled[j];
		j++;
	}
	if (! smart) {
		// the problem here is that leaving out the second shuffle automatically makes the resulting list more or less usable; it's less random but this lack of randomness makes it more likely other requirements (that aren't yet implemented) are met
		// however, an undesired side effect is that board members are only assigned to some random dates early in the year
		fisherYatesShuffle( memberAssignees );
	}
	
	var assigneeIndex = 0;
	for (var dateIndex = 0; dateIndex < dates.length; dateIndex++) {
		this.data[dateIndex] = new Array(membersPerDate);
		for (var i = 0; i < membersPerDate; i++) {
			
			this.data[dateIndex][i] = memberAssignees[assigneeIndex];
			assigneeIndex++;
		}
	}
}


SKGB.StegdienstListe.prototype.generateRandomSuggestions = function (members, dates, membersPerDate, smart) {
	
	for (var dateIndex = 0; dateIndex < dates.length; dateIndex++) {
		this.data[dateIndex] = new Array(membersPerDate);
		for (var i = 0; i < membersPerDate; i++) {
			
			// the 'strategy': simply randomize everything
			var memberIndex = parseInt(Math.random() * members.length);
			
			this.data[dateIndex][i] = members[memberIndex];
		}
	}
}


SKGB.StegdienstListe.prototype.generateSortedSuggestions = function (members, dates, membersPerDate, sortKey, descending) {
	// assumption: input array from 'database' is already sorted by last name (which BTW also alleviates the need for sorting the statistics list on the right)
	
	var membersSorted = members.slice().sort(function (a, b) {
		var order = sortKey(a) > sortKey(b) ? 1 : sortKey(a) < sortKey(b) ? -1 : 0;
		if (descending) {
			order *= -1;
		}
		return order;
	});
	
	var memberIndex = 0;
	for (var dateIndex = 0; dateIndex < dates.length; dateIndex++) {
		this.data[dateIndex] = new Array(membersPerDate);
		for (var i = 0; i < membersPerDate; i++) {
			
			// the 'strategy': simply sequential; reset the member's list when it has been run through
			if (memberIndex >= membersSorted.length) {
				memberIndex = 0;  
			}
			this.data[dateIndex][i] = membersSorted[memberIndex];
			memberIndex++;
		}
	}
}


SKGB.StegdienstListe.prototype.generateNoSuggestions = function (members, dates, membersPerDate) {
	for (var i = 0; i < dates.length; i++) {
		this.data[i] = new Array(membersPerDate);
		for (var j = 0; j < membersPerDate; j++) {
			this.data[i][j] = null;
		}
	}
}


SKGB.StegdienstListe.prototype.importData = function (members, dates, membersPerDate, importDataAsString) {
	function m (name) {
		for (var i = 0; i < members.length; i++) {
			if (members[i].name == name) {
				return members[i];
			}
		}
		return null;
	}
	
	// parse import data
	var lines = importDataAsString.replace(/\r\n/g, '\n').replace(/\r/g, '\n').split('\n');
	var importData = new Array(lines.length);
	for (var i = 0; i < lines.length; i++) {
		var fields = lines[i].replace(/"/g, '').replace(/;|,/g, '\t').split('\t');
		importData[i] = new Array(fields.length);
		for (var j = 0; j < fields.length; j++) {
			importData[i][j] = fields[j];
		}
	}
	
	// create model
	for (var i = 0; i < dates.length; i++) {
		this.data[i] = new Array(membersPerDate);
		for (var j = 0; j < membersPerDate; j++) {
			if (i >= importData.length || j >= importData[i].length) {
				this.data[i][j] = null;
				continue;
			}
			
			this.data[i][j] = m( importData[i][j] );
		}
	}
}


SKGB.StegdienstListe.prototype.updateCount = function () {
	for (var i = 0; i < this.members.length; i++) {
		this.members[i].count = 0;
	}
	for (var i = 0; i < this.data.length; i++) {
		var dateItem = this.data[i];
		if (! dateItem) { continue; }
		// the items of the dateItem are member objects
		if (dateItem[0]) {
			dateItem[0].count += 1;
		}
		if (dateItem[1]) {
			dateItem[1].count += 1;
		}
	}
}



// ====================================================

SKGB.StegdienstListeInterface = function (uiBindings) {
	if (uiBindings) {
		this.ui = uiBindings;
	}
}
SKGB.StegdienstListeInterface.constructor = SKGB.StegdienstListeInterface;

SKGB.StegdienstListeInterface.prototype.liste = null;  // SKGB.StegdienstListe instance
SKGB.StegdienstListeInterface.prototype.ui = null;  // uiBindings
SKGB.StegdienstListeInterface.prototype.activeMemberCells = null;  // cells containing members currently being dragged


SKGB.StegdienstListeInterface.prototype.resetInterface = function () {
	this.ui.memberPrototypesListNode.innerHTML = '';
	this.ui.tableBody.innerHTML = '';
}


SKGB.StegdienstListeInterface.prototype.generatePrototypes = function () {
	var statListNode = this.ui.memberPrototypesListNode;
	var members = this.liste.members;
	
	for (var i = 0; i < members.length; i++) {
		var item = { member: members[i], domNode: document.createElement('LI') };
		this.createDraggableHtmlMemberElement(item, 'clone');
		
		var countNode = document.createElement('DIV');
		countNode.className = 'count';
		countNode.id = 'countNode' + members[i].id;
		countNode.innerHTML = '-';
		item.domNode.insertBefore(countNode, item.domNode.firstChild);
		
		statListNode.appendChild(item.domNode);
	}
	
	// the trash
	var instance = this;
	$(statListNode).droppable({
		scope: 'members',
//		hoverClass: 'ui-state-hover',
		tolerance: 'pointer',
		drop: function (event, ui) {
			new SKGB.StegdienstListeDrop(event, ui, instance).on(this);
		}
	});
}


SKGB.StegdienstListeInterface.prototype.importData = function (dates) {
	var members = this.liste.members;
	var membersPerDate = this.membersPerDate();
	
	this.liste.importData(members, dates, membersPerDate, this.ui.importData.value);
	
	// add suggestions to UI table
//	this.createStegdienstDom(dates);
}


SKGB.StegdienstListeInterface.prototype.membersPerDate = function () {
	// the number of members per date is usually 2, but occasionally has been 3 in the past during summertime
	var membersHeader = this.ui.membersColumnTableHeaderCell;
	return membersHeader.colSpan;
}


SKGB.StegdienstListeInterface.prototype.generateSuggestions = function (dates) {
	var members = this.liste.members;
	var membersPerDate = this.membersPerDate();
	
	// actually generate those suggestions
	var strategy = $('#strategy input[name="strategy"]:checked')[0].value;
	if (strategy == 'random') {
		var smart = $('#strategy input[name="smart"]')[0].checked;
		var replacement = $('#strategy input[name="randomiser"]:checked')[0].value == 'with';
		if (replacement) {
			this.liste.generateRandomSuggestions(members, dates, membersPerDate, smart);
		}
		else {
			this.liste.generateShuffledSuggestions(members, dates, membersPerDate, smart);
		}
	}
	else if (strategy == 'sorted') {
		var sortKey = $('#strategy input[name="sortkey"]:checked')[0].value
		var descending = $('#strategy input[name="descending"]')[0].checked;
		this.liste.generateSortedSuggestions(members, dates, membersPerDate, function (member) {
			if (sortKey == 'id') {
				return member.id;
			}
			if (sortKey == 'firstname') {
				return member.name;
			}
			if (sortKey == 'lastname') {
				return undefined;
			}
			throw 'sortkey not implemented';
		}, descending);
	}
	else if (strategy == 'base') {
		var historyKey = $('#strategy select[name="basedata"] option:selected')[0].value
		this.liste.importData(members, dates, membersPerDate, $('#importdata' + historyKey)[0].value);
	}
	else if (strategy == 'blank') {
		this.liste.generateNoSuggestions(members, dates, membersPerDate);
	}
	else if (strategy == 'montecarlo') {
		this.liste.generateMonteCarloSuggestions(members, dates, membersPerDate);
	}
	else {
		throw 'strategy not implemented';
	}
	
	// add suggestions to UI table
//	this.createStegdienstDom(dates);
}


SKGB.StegdienstListeInterface.prototype.createStegdienstDom = function (dates) {
//	var data = SKGB.stegdienstListe.data;
	var data = this.liste.data;
	
	// add suggestions to UI table
	var date = new Date(dates.start);
	for (var i = 0; i < this.liste.data.length; i++) {
		this.createDomTableRowNodes(this.liste.data[i], this.formatDate(date));
		date.setDate(date.getDate() + 7);
	}
	
	$('#tabs').tabs('select', 3);
	location.hash = "#tabs";
	
//	this.dataHasChanged();
	// open question: does this function assume that the model is already in its correct state?
}


SKGB.StegdienstListeInterface.prototype.createDomTableRowNodes = function (suggestion, dateString) {
	
	var membersHeader = this.ui.membersColumnTableHeaderCell;
	var membersPerDate = membersHeader.colSpan;
	var tableBody = this.ui.tableBody;
	var listItemForCurrentDate = new Array(membersPerDate);
	var tableRowString = '';
	
	// the header order in the HTML determines the order of the table columns
	var header = this.ui.tableHeaderRow;
	for (var j = 0; j < header.childNodes.length; j++) {
		switch (header.childNodes[j].id) {
			
			case 'date-col':
				tableRowString += '<TD>' + dateString + '</TD>';
				continue;
			
			case 'member-cols':
				this.firstMemberColumnIndex = j;
				for (var k = 0; k < membersPerDate; k++) {
					listItemForCurrentDate[k] = { member: suggestion ? suggestion[k] : null, domNode: null };
					tableRowString += '<TD CLASS="member"></TD>';
				}
				continue;
			
			case 'warning-col':
				tableRowString += '<TD CLASS="warning"></TD>';
				continue;
			
			default:
				tableRowString += '<TD></TD>';
		}
	}
	
	var tableRow = document.createElement('TR');
	tableRow.innerHTML = tableRowString;
	tableBody.appendChild(tableRow);
	
	var instance = this;
	var memberCells = $(tableRow).find('.member');
	for (var j = 0; j < memberCells.length; j++) {
		listItemForCurrentDate[j].domNode = memberCells[j];
		if (listItemForCurrentDate[j].member) {
			this.createDraggableHtmlMemberElement(listItemForCurrentDate[j]);
		}
		
		$(listItemForCurrentDate[j].domNode).droppable({
			scope: 'members',
//			hoverClass: 'ui-state-hover',
			tolerance: 'pointer',
//			drop: function(event, ui) { instance.handleDrop(event, ui, this); }
			drop: function (event, ui) {
				new SKGB.StegdienstListeDrop(event, ui, instance).on(this);
			}
		});
	}
}


SKGB.StegdienstListeInterface.prototype.formatDate = function (date) {
	var year = date.getFullYear();
	var month = date.getMonth() + 1;
	var day = date.getDate();
	return '' + year + '-' + (month < 10 ? '0' : '') + month + '-' + (day < 10 ? '0' : '') + day;
}


SKGB.StegdienstListeInterface.prototype.createDraggableHtmlMemberElement = function (memberObject, dragMode) {
	
	var nahFern = memberObject.member.remote ? '<SPAN CLASS="fern">F</SPAN> ' : '<SPAN CLASS="nah">N</SPAN> ';
	var vorstand = memberObject.member.board ? ' <SPAN CLASS="vorstand">V</SPAN>' : memberObject.member.exempt ? ' <SPAN CLASS="befreit">B</SPAN>' : '';
	
	memberObject.domNode.innerHTML = '<DIV CLASS="ui-state-default ui-corner-all">' + nahFern + memberObject.member.name + vorstand + '<INPUT TYPE="hidden" NAME="id" VALUE="' + memberObject.member.id + '"></DIV>';
	var div = $(memberObject.domNode).find('DIV')[0];
	
	var controller = this;
	
	$(div).draggable({
		start: function () {
			controller.draggingMember(memberObject.member);
		},
		stop: function () {
			controller.draggingMember(null);
		},
		scope: 'members',
		containment: 'document',
		opacity: 1,
		distance: 0,
		revert: 'invalid',
		revertDuration: SKGB.StegdienstListeDrop.prototype.animationDuration,
//		stack: 'TABLE#stegdienst TD.member>DIV',
		helper: dragMode ? dragMode : 'original'
	});
	div.member = memberObject.member;  // :TODO: get rid of this horrible hack
	
	return div;
}


SKGB.StegdienstListeInterface.prototype.draggingMember = function (member) {
	if (this.activeMemberCells) {
		for (var i = 0; i < this.activeMemberCells.length; i++) {
			$( this.activeMemberCells[i].firstChild ).toggleClass('activeMember', false);
		}
		this.activeMemberCells = null;
	}
	
	if (member) {
		this.activeMemberCells = new Array();
		for (var i = 0; i < this.liste.data.length; i++) {
			if (! this.liste.data[i]) { continue; }
			for (var j = 0; j < this.liste.data[i].length; j++) {
				if (this.liste.data[i][j] && this.liste.data[i][j].id == member.id) {
					var tableCell = this.ui.getTableCell(i, j);
					this.activeMemberCells.push(tableCell);
					$( tableCell.firstChild ).toggleClass('activeMember', true);
				}
			}
		}
	}
}


SKGB.StegdienstListeInterface.prototype.dataHasChanged = function () {
	// open question: can this function assume that the model is already in its correct state?
	// (might be a problem if a drag happens before the animation's finished)
	
	this.updateExport();
	this.liste.updateCount();
	
	var warnings = new SKGB.StegdienstListeWarningList(this.liste);
//	this.warnings = warnings;  // debug
	warnings.updateWarningsHtml();
	this.ui.warningsArea.innerHTML = '<P>' + warnings.asHtml() + '\n\n<P><EM>score: ' + warnings.score() + '</EM>';
	$('#scorebutton')[0].value = warnings.displayScore();
	$('#warningsbutton')[0].value = warnings.warnings.length + ' Warnung' + (warnings.warnings.length == 1 ? '' : 'en');
	
	// dish out some warnings :)
//	this.updateDateWarnings();
}


SKGB.StegdienstListeInterface.prototype.updateExport = function () {
	var data = this.liste.data;
	var a = '';
	for (var i = 0; i < data.length; i++) {
		if (data[i].length > 0) {
			if (data[i][0]) {
				a += data[i][0].name;
			}
			for (var j = 1; j < data[i].length; j++) {
				a += '\t';
				if (data[i][j]) {
					a += data[i][j].name;
				}
			}
		}
		a += '\n';
	}
	this.ui.exportData.innerHTML = a;
}


SKGB.StegdienstListeInterface.prototype.interactiveChange = function (change) {
	if (change.type == 'clear') {
		this.liste.assign(change.from, null);
	}
	else if (change.type == 'assign') {
		this.liste.assign(change.to, change.from);
	}
	else {  // swap
		var oldFrom = this.liste.assignment(change.from);
		var oldTo = this.liste.assignment(change.to);
		this.liste.assign(change.from, oldTo);
		this.liste.assign(change.to, oldFrom);
	}
	this.liste.stale = true;
}



// ====================================================

SKGB.StegdienstListeDrop = function (event, jQueryUi, delegate) {
	this.controller = delegate;
	// obtain references to DOM nodes
	this.prototypeContainer = this.controller.ui.memberPrototypesListNode;
	this.trashNode = this.controller.ui.trashDropTargetNode;
	this.draggable = jQueryUi.draggable.context;
	this.originContainer = jQueryUi.draggable.context.parentNode;
}
SKGB.StegdienstListeDrop.constructor = SKGB.StegdienstListeDrop;

SKGB.StegdienstListeDrop.prototype.controller = null;  // SKGB.StegdienstListeInterface instance
SKGB.StegdienstListeDrop.prototype.animationDuration = 400;  // ms
SKGB.StegdienstListeDrop.prototype.cancelled = false;


SKGB.StegdienstListeDrop.prototype.on = function (destContainer) {
	this.destContainer = destContainer;
	this.destContainerContentArray = $(this.destContainer).find('DIV');
	this.destContainerContent = this.destContainerContentArray.length > 0 ? this.destContainerContentArray[0] : null;
	
	this.analyseDragType();
	if (this.cancelled) {
		return;
	}
	
	var references = {
		origin: this.getPositionReference(this.originContainer),
		destination: this.getPositionReference(this.destContainer)
	};
	
	this.showChanges();
	this.notifyDelegate(references);
}


SKGB.StegdienstListeDrop.prototype.analyseDragType = function () {
	// cases:
	// 1: from table cell to other table cell, replacing existing member => swap
	// 2: from table cell to same table cell => cancel
	// 3: from table cell to 'trash' (stats) => remove
	// 4: from stats to empty table cell => add
	// 5: from stats, replacing existing member => remove + add
	// 6: from stats to 'trash' (stats) => cancel
	// 7: from table cell to empty table cell => move
	
	// analyse what kind of drag is happening
	this.dragFromPrototype = this.originContainer.parentNode == this.prototypeContainer;  // :FIXME: (fix what ??)
	this.dragToTrash = this.destContainer == this.trashNode;
	this.cancelDrag = this.dragFromPrototype && this.dragToTrash || this.originContainer == this.destContainer;
	this.replaceDragTarget = ! this.dragToTrash && this.destContainerContent;
//	this.dragToEmptyCell = ! this.dragToTrash && ! this.replaceDragTarget;
	
	// cancel any drag that wouldn't change state anyway
	if (this.cancelDrag) {
		this.cancelled = true;
		this.resetNodePosition(this.draggable);
		console.info('drag cancelled (case 2, 6)');
		
	}
	else if (this.dragToTrash) {
		console.info('case 3');
	}
	else {
		if (this.dragFromPrototype) {
			if (this.replaceDragTarget) {
				console.info('case 5');
			}
			else {
				console.info('case 4');
			}
		}
		else {
			if (this.replaceDragTarget) {
				console.info('case 1');
			}
			else {
				console.info('case 7');
			}
		}
	}
}


SKGB.StegdienstListeDrop.prototype.getPositionReference = function (node) {	
	var reference = {
		inTable: this.controller.ui.tableBody == node.parentNode.parentNode,
		inPrototypes: this.controller.ui.memberPrototypesListNode == node.parentNode,
		level1Index: $(node.parentNode.childNodes).index(node),
		level2Index: $(node.parentNode.parentNode.childNodes).index(node.parentNode)
	};
	if (! reference.inTable && ! reference.inPrototypes || reference.inTable && reference.inPrototypes) {
		// the DOM doesn't have the expected structure; bailing out
		return null;
	}
	
	if (reference.inTable) {
		// adjust position for other table columns
		reference.level1Index -= this.controller.firstMemberColumnIndex;
//		reference.level2Index -= 1;  // huh? apparently we have a ghost row #0
	}
	else {
		reference.level2Index = -1;  // a second level is not meaningful for a list
	}
	
	return reference;
}


SKGB.StegdienstListeDrop.prototype.showChanges = function () {
	var self = this;
	
	// DOM modification and additional animation according to kind of drag
	
	if (this.dragToTrash) {  // [case 3]
		// animation
		$(this.draggable).animate({ opacity: 0 }, this.animationDuration / 2, function() {
			// remove node from DOM
			self.draggable.parentNode.removeChild(self.draggable);
		});
		
	}
	else if (this.dragFromPrototype) {  // [cases 4+5]
		// create new DOM node
		var item = { member: this.draggable.member, domNode: this.destContainer };
		var div = this.controller.createDraggableHtmlMemberElement(item);
		// animation
		$(div).animate({ opacity: 0 }, this.animationDuration / 2, function() {
			$(div).animate({ opacity: 1 }, self.animationDuration / 2);
		});
		
	}
	else {  // change within StegdienstListe table [cases 1+7]
		// move (forward)
		this.moveWithAnimation(this.draggable, this.destContainer);
		// swap (reverse)
		if (this.replaceDragTarget) {  // [case 7]
			this.moveWithAnimation(this.destContainerContent, this.originContainer);  // animate move of replaced element
		}
	}
}


SKGB.StegdienstListeDrop.prototype.moveWithAnimation = function (fromNode, toContainer) {
	var self = this;
	$(fromNode).addClass('animated');
	$(fromNode).animate({
		top: (toContainer.offsetTop - fromNode.parentNode.offsetTop),
		left: (toContainer.offsetLeft - fromNode.parentNode.offsetLeft)
	}, {
		complete: function() {
			fromNode.parentNode.removeChild(fromNode);
			$(fromNode).removeClass('animated');
			self.resetNodePosition(fromNode);
			toContainer.appendChild(fromNode);
		},
		duration: this.animationDuration
	});
}


SKGB.StegdienstListeDrop.prototype.resetNodePosition = function (fromNode) {
	fromNode.style.top = 0;
	fromNode.style.left = 0;
}


SKGB.StegdienstListeDrop.prototype.notifyDelegate = function (references) {
	
	if (this.dragToTrash) {
		this.controller.interactiveChange({
			type: 'clear',
			from: { row: references.origin.level2Index, col: references.origin.level1Index },
			to: null
		});
	}
	else if (this.dragFromPrototype) {
		this.controller.interactiveChange({
			type: 'assign',
			from: references.origin.level1Index,
			to: { row: references.destination.level2Index, col: references.destination.level1Index }
		});
	}
	else {
		this.controller.interactiveChange({
			type: 'swap',
			from: { row: references.origin.level2Index, col: references.origin.level1Index },
			to: { row: references.destination.level2Index, col: references.destination.level1Index }
		});
	}
	
	// at this point the internal business model state is (assumed to be) updated
	this.controller.dataHasChanged();
}



// ====================================================

SKGB.print = function () {
	var stegdienst = SKGB.stegdienstController;
	var firstDate = stegdienst.formatDate(stegdienst.liste.firstDate);
	var data = stegdienst.ui.exportData.innerHTML;
//	var dataEncoded = btoa(unescape(encodeURIComponent(data)));
	var dataEncoded = btoa(data);
//	dataEncoded = encodeURIComponent(dataEncoded.replace(/\//g, '_').replace(/\+/g, '-').replace(/=/g, ''));  // RFC4648
	dataEncoded = encodeURIComponent(dataEncoded);
	location.href="/stegdienst/drucken?start="+firstDate+"&liste="+dataEncoded;
}



// ====================================================

function getMemberReference (node) {
	// better: data-* and .dataset
	var idNode = $(node).find('INPUT[name=id]').get(0);
	var id = parseInt(idNode.value);
	var members = window.params.members;
	for (var i = 0; i < members.length; i++) {
		if (members[i].id == id) {
			return members[i];
		}
	}
	return null;
}



// ====================================================

SKGB.StegdienstListeWarningList = function (liste) {
	this.liste = liste;
	this.warnings = [];
	// method to add new warning
	// manages all the details
	this.memberWarnings();
	this.dateWarnings();
	// supposed to read config (warning penalties etc) from UI, but has them hard-coded at the beginning
/*
	// BUG: this sort causes the warnings to have wrong severities; why?
	this.warnings.sort(function (a, b) {
		return b.severityAsInt() - a.severityAsInt();
	});
*/
}
SKGB.StegdienstListeWarningList.prototype.updateWarningsHtml = function () {
	this.updateMemberWarningsHtml();
	this.updateDateWarningsHtml();
	// supposed to read config (warning penalties etc) from UI, but has them hard-coded at the beginning
}
// has a list of warnings
// method to clear list = simply new()
//SKGB.StegdienstListeWarningList.prototype.warnings = [];  // wird dies wirklich geklont bei new?

// method to write warnings to warning list
SKGB.StegdienstListeWarningList.prototype.asText = function () {
	var text = '';
	for (var i = 0; i < this.warnings.length; i++) {
		text += this.warnings[i].asString() + '\n';
	}
	return text;
}

// method to write warnings to warning list
SKGB.StegdienstListeWarningList.prototype.asHtml = function () {
	var text = '';
	for (var i = 0; i < this.warnings.length; i++) {
		text += this.warnings[i].asHtml();
		text += this.warnings[i].severityAsInt() >= 2 ? ' <STRONG>' : ' ';
		text += this.warnings[i].asString();
		text += this.warnings[i].severityAsInt() >= 2 ? '</STRONG>\n<BR>' : '\n<BR>';
	}
	return text;
}

SKGB.StegdienstListeWarningList.prototype.memberWarnings = function () {
	// calculate statistics
	var countFrequency = [0];
	var boardMemberCount = 0;
	var exemptMemberCount = 0;
	for (var i = 0; i < this.liste.members.length; i++) {
		var count = this.liste.members[i].count;
		if (countFrequency[count]) {
			countFrequency[count] += 1;
		}
		else {
			countFrequency[count] = 1;
		}
		if (this.liste.members[i].board) {
			boardMemberCount += 1;
		}
		if (this.liste.members[i].exempt) {
			exemptMemberCount += 1;
		}
	}
	 
	// find the modus
	// (median would perhaps be better here, as modus seems to require a fairly even distribution to achieve the result we want here)
	var modus = 0;
	for (var i = 0; i < countFrequency.length; i++) {
		if (typeof countFrequency[i] === 'undefined') { continue; }
		if (countFrequency[i] >= countFrequency[modus]) {
			modus = i;
			// don't break: find highest match if results are bi-modal
		}
	}
	
//	var memberCountWithoutBoard = this.liste.members.length - boardMemberCount - exemptMemberCount;
//	var dateItemCount = this.liste.data.length * 2;
//	var expectedMaxCount = Math.ceil( dateItemCount / memberCountWithoutBoard );
	
	// warnings and member statistics
	for (var i = 0; i < this.liste.members.length; i++) {
		var member = this.liste.members[i];
		var countNode = $('#countNode' + member.id)[0];
		if (! countNode) { continue; }  // why???????????????
		
		if (member.count == 0 && ! member.exempt) {
			this.warnings.push( new SKGB.StegdienstListeMemberWarning({
				severity: 'check',
				text: 'nirgends eingeteilt',
				member: member
			}) );
		}
		else if (member.count < modus && ! member.exempt && (! member.board || member.count < member.idealCount)) {
			this.warnings.push( new SKGB.StegdienstListeMemberWarning({
				severity: 'note',
				text: 'seltener eingeteilt als andere',
				member: member
			}) );
		}
		if (member.count > member.idealCount + 1) {
			this.warnings.push( new SKGB.StegdienstListeMemberWarning({
				severity: 'error',
				text: (member.board ? 'Vorstandsmitglied und ' : member.exempt ? 'befreit und ' : '') + 'zu oft eingeteilt',
				member: member
			}) );
		}
		else if (member.exempt && member.count > 0) {
			this.warnings.push( new SKGB.StegdienstListeMemberWarning({
				severity: 'check',
				text: 'befreit und sollte nicht eingeteilt werden',
				member: member
			}) );
		}
/*
		else if (member.count > member.idealCount && member.board) {
			this.warnings.push( new SKGB.StegdienstListeMemberWarning({
				severity: 'check',
				text: 'Vorstandsmitglied und sollte nur ' + member.idealCount + 'mal eingeteilt werden',
				member: member
			}) );
		}
*/
		else if (member.count > modus) {
			this.warnings.push( new SKGB.StegdienstListeMemberWarning({
				severity: 'note',
				text: 'öfter eingeteilt als andere',
				member: member
			}) );
		}
	}
}

SKGB.StegdienstListeWarningList.prototype.dateWarnings = function () {
	
	// warnings for individual dates
	for (var i = 0; i < this.liste.data.length; i++) {
		var dateItem = this.liste.data[i];
		if (! dateItem) { continue; }
//		var warningNode = this.ui.getTableWarningCellInRow(i);
		var warningClass = 'ok';
		var warningText = '';
		
		// if a member slot is empty, the object is undefined; therefore we add the error message immediately and skip everything else to avoid JS errors
		if (! dateItem[0] || ! dateItem[1]) {
			this.warnings.push( new SKGB.StegdienstListeDateWarning({
				severity: 'error',
				text: 'Es sind zu wenige Mitglieder für diesen Termin eingeteilt.',
				dateIndex: i
			}) );
			continue;
		}
		
		if (dateItem[0].remote && dateItem[1].remote) {
			this.warnings.push( new SKGB.StegdienstListeDateWarning({
				severity: 'note',
				text: 'Alle Mitglieder dieses Datums sind &quot;fern&quot;.',
				dateIndex: i
			}) );
		}
		if (i > 0 && (
				dateItem[0] && this.liste.data[i - 1][0] && dateItem[0].id == this.liste.data[i - 1][0].id ||
				dateItem[0] && this.liste.data[i - 1][1] && dateItem[0].id == this.liste.data[i - 1][1].id )) {
			this.warnings.push( new SKGB.StegdienstListeDateWarning({
				severity: 'check',
				text: 'Ein Mitglied ist für unmittelbar aufeinander folgende Daten vorgesehen.',
				dateIndex: i,
				member: this.liste.data[i][0]
			}) );
		}
		if (i > 0 && (
				dateItem[1] && this.liste.data[i - 1][0] && dateItem[1].id == this.liste.data[i - 1][0].id || 
				dateItem[1] && this.liste.data[i - 1][1] && dateItem[1].id == this.liste.data[i - 1][1].id )) {
			this.warnings.push( new SKGB.StegdienstListeDateWarning({
				severity: 'check',
				text: 'Ein Mitglied ist für unmittelbar aufeinander folgende Daten vorgesehen.',
				dateIndex: i,
				member: this.liste.data[i][1]
			}) );
		}
		if (dateItem[0].id == dateItem[1].id) {
			this.warnings.push( new SKGB.StegdienstListeDateWarning({
				severity: 'error',
				text: 'Ein Mitglied ist mehrfach für dasselbe Datum vorgesehen.',
				dateIndex: i,
				member: dateItem[0]
			}) );
		}
		
//		warningNode.innerHTML = this.getWarningSymbolHtml(warningClass, warningText);
	}
	
	// warnings for individual members
	
	// other warnings (if any)
}

// method(s) (or automatism?) to write warning(s) to individual items, taking into account precedence (not yet)
SKGB.StegdienstListeWarningList.prototype.updateMemberWarningsHtml = function () {
	for (var i = 0; i < this.liste.members.length; i++) {
		var member = this.liste.members[i];
		var countNode = $('#countNode' + member.id)[0];
		if (! countNode) { continue; }
		var warningClass = 'ok';
		var warningText = undefined;
		// besser indizieren?
		var statisticsHtml = '' + member.count + ' <IMG SRC="icons/warning-ok.png" WIDTH=16 HEIGHT=16 ALT="">';
		var highestSeverity = 0;
		for (var j = 0; j < this.warnings.length; j++) {
			if (! this.warnings[j] instanceof SKGB.StegdienstListeMemberWarning) {
				continue;
			}
			if (this.warnings[j].member != member) {
				continue;
			}
			var severity = this.warnings[j].severityAsInt();
			if (severity >= highestSeverity) {
				statisticsHtml = '' + this.warnings[j].member.count + ' ' + this.warnings[j].asHtml();
				highestSeverity = severity;
			}
		}
		countNode.innerHTML = statisticsHtml;
	}
}

SKGB.StegdienstListeWarningList.prototype.updateDateWarningsHtml = function () {
	for (var i = 0; i < this.liste.data.length; i++) {
		var dateItem = this.liste.data[i];
		if (! dateItem) { continue; }
		var warningNode = $($('TABLE#stegdienst>TBODY>TR')[i]).find('TD.warning')[0];
/*
		var warningNode = this.ui.getTableWarningCellInRow(i);
			getTableWarningCellInRow: function (i) {
				return $($('TABLE#stegdienst>TBODY>TR')[i]).find('TD.warning')[0];
			},
*/
		var warningClass = 'ok';
		var warningText = '';
		
		var statisticsHtml = '<IMG SRC="icons/warning-ok.png" WIDTH=16 HEIGHT=16 ALT="">';
		var highestSeverity = 0;  // not sure if we need this for the Date warnings
		for (var j = 0; j < this.warnings.length; j++) {
			if (! this.warnings[j] instanceof SKGB.StegdienstListeDateWarning) {
				continue;
			}
			if (this.warnings[j].dateIndex != i) {
				continue;
			}
			var severity = this.warnings[j].severityAsInt();
			if (severity >= highestSeverity) {
				statisticsHtml = this.warnings[j].asHtml();
				highestSeverity = severity;
			}
		}
		warningNode.innerHTML = statisticsHtml;
	}
	$('IMG.warninglink').click(function () {
		$('#tabs').tabs('select', 2);
	});
	
	// other warnings (if any)
}

SKGB.StegdienstListeWarningList.prototype.score = function () {
//	return 0 - this.warnings.length;
	var score = 0;
	for (var i = 0; i < this.warnings.length; i++) {
		var severity = this.warnings[i].severity;
		if (severity == 'ok') {
			score -= 0;
		}
		else if (severity == 'note') {
			score -= 0.5;
		}
		else if (severity == 'check') {
			score -= 5;
		}
		else if (severity == 'error') {
			score -= 10;
		}
		else {
			throw 'undefined warning severity';
		}
	}
	return score;
}

SKGB.StegdienstListeWarningList.prototype.displayScore = function () {
	return Math.floor(this.score());
//	return Math.round(this.score() * 10) / 10;  // debug
}


SKGB.StegdienstListeWarning = function (options) {
	this.init(options);
}
SKGB.StegdienstListeWarning.prototype.init = function (options) {
	if (! options) { return; }
	this.severity = options.severity;
	this.text = options.text;
	this.member = options.member;
	this.dateIndex = options.dateIndex;
}
SKGB.StegdienstListeWarning.prototype.severity = undefined;
SKGB.StegdienstListeWarning.prototype.text = undefined;
SKGB.StegdienstListeWarning.prototype.asHtml = function () {
	if (this.severity == 'ok') {
		return '<IMG SRC="icons/warning-ok.png" WIDTH=16 HEIGHT=16 ALT="">';
	}
	else if (this.severity == 'note') {
		return '<IMG SRC="icons/warning-note.png" WIDTH=16 HEIGHT=16 ALT="' + this.text + '" TITLE="Hinweis: ' + this.text + '" CLASS="warninglink">';
	}
	else if (this.severity == 'check') {
		return '<IMG SRC="icons/warning-caution.png" WIDTH=16 HEIGHT=16 ALT="' + this.text + '" TITLE="Warnung: ' + this.text + '" CLASS="warninglink">';
	}
	else if (this.severity == 'error') {
		return '<IMG SRC="icons/warning-error.png" WIDTH=16 HEIGHT=16 ALT="' + this.text + '" TITLE="Fehler: ' + this.text + '" CLASS="warninglink">';
	}
	throw 'unknown warning class';
}
SKGB.StegdienstListeWarning.prototype.severityAsString = function () {
	return this.severity == 'error' ? 'FEHLER' : this.severity == 'check' ? 'Warnung' : this.severity == 'note' ? 'Hinweis' : this.severity;
}
SKGB.StegdienstListeWarning.prototype.severityAsInt = function () {
	return this.severity == 'error' ? 3 : this.severity == 'check' ? 2 : this.severity == 'note' ? 1 : 0;
}

SKGB.StegdienstListeMemberWarning = function (options) {
	this.init(options);
}
SKGB.StegdienstListeMemberWarning.prototype = new SKGB.StegdienstListeWarning();
SKGB.StegdienstListeMemberWarning.prototype.asString = function () {
	return this.severityAsString() + ': ' + this.member.name + ': ist ' + this.text;
}
SKGB.StegdienstListeDateWarning = function (options) {
	this.init(options);
}
SKGB.StegdienstListeDateWarning.prototype = new SKGB.StegdienstListeWarning();
SKGB.StegdienstListeDateWarning.prototype.asString = function () {
	var info = this.dateIndex;
	info = $($('TABLE#stegdienst>TBODY>TR')[this.dateIndex]).find('TD')[1].innerHTML;
	if (this.member) {
		info += ' / ' + this.member.name;
	}
	return this.severityAsString() + ': ' + info + ': ' + this.text;
}
