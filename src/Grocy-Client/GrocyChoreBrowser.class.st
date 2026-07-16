"
Graphical version of the grocy chores
"
Class {
	#name : 'GrocyChoreBrowser',
	#superclass : 'SpPresenter',
	#instVars : [
		'client',
		'choreList',
		'refreshButton',
		'searchField',
		'allChores',
		'debugMode',
		'statusLabel',
		'timerProcess',
		'notifiedChoreIds'
	],
	#category : 'Grocy-Client',
	#package : 'Grocy-Client'
}

{ #category : 'layout' }
GrocyChoreBrowser class >> defaultLayout [
	^ SpBoxLayout newVertical
		spacing: 5;
		add: #searchField expand: false;
		add: #choreList;
		add: #refreshButton expand: false;
		add: #statusLabel expand: false;
		yourself
]

{ #category : 'initialization' }
GrocyChoreBrowser >> connectPresenters [
	refreshButton action: [ self refreshChoreList ].
	searchField whenTextChangedDo: [ :text | self updateFilteredList ].

	"Hier aktivieren wir das Rechtsklick-Menü auf der Tabelle"
	choreList contextMenu: self createContextMenu
]

{ #category : 'context menu' }
GrocyChoreBrowser >> createContextMenu [
	"Erstellt das Rechtsklick-Menü für die ausgewählte Aufgabe"
	^ self newMenu
		addItem: [ :item |
			item
				name: 'Als erledigt markieren';
				icon: (self iconNamed: #testGreen);
				action: [ self executeSelectedChore ] ];
		addItem: [ :item |
			item
				name: 'Aufgabe überspringen (Skip)';
				icon: (self iconNamed: #testGray);
				action: [ self skipSelectedChore ] ]
]

{ #category : 'initialization' }
GrocyChoreBrowser >> dateColumn [
	^ (SpStringTableColumn title: 'Fällig am' evaluated: [ :chore | self formatDateString: chore nextExecution ])
		beSortable
]

{ #category : 'updating' }
GrocyChoreBrowser >> executeSelectedChore [
	choreList selectedItem ifNotNil: [ :chore |
		[
			client executeChoreId: chore id.

			notifiedChoreIds remove: chore id ifAbsent: [ "egal" ].

			self refreshChoreList.
			self inform: ('Aufgabe "{1}" erfolgreich erledigt!' format: { chore name }).
		] on: Error do: [ :err |
			self inform: 'Fehler beim Erledigen: ', err messageText ] ]
]

{ #category : 'formatting' }
GrocyChoreBrowser >> formatDateString: aString [
	"Schneidet die Uhrzeit ab, falls der String lang genug ist"
	aString ifNil: [ ^ 'Kein Datum' ].
	^ aString size >= 10
		ifTrue: [ aString copyFrom: 1 to: 10 ]
		ifFalse: [ aString ]
]

{ #category : 'initialization' }
GrocyChoreBrowser >> idColumn [
	^ (SpStringTableColumn title: 'ID' evaluated: [ :chore | chore id asString ])
		beSortable
]

{ #category : 'initialization' }
GrocyChoreBrowser >> initialize [

	| gespeicherterKey eingabe |
	super initialize.
	allChores := OrderedCollection new.
	notifiedChoreIds := Set new.
	debugMode := false.

	gespeicherterKey := GrocyChoreClient defaultApiKey.

	gespeicherterKey ifNil: [
			eingabe := UIManager default request: 'ERSTER START: API-KEY BENÖTIGT

Bitte gib deinen Grocy API-Key ein:'.

			"Prüfen, ob der Nutzer Text eingegeben und nicht Abbrechen geklickt hat"
			(eingabe notNil and: [ eingabe trimBoth isNotEmpty ]) ifTrue: [
					GrocyChoreClient defaultApiKey: eingabe trimBoth.
					gespeicherterKey := eingabe trimBoth ] ].

	client := GrocyChoreClient new.
	client apiKey: gespeicherterKey
]

{ #category : 'initialization' }
GrocyChoreBrowser >> initializePresenters [
	searchField := self newTextInput.
	searchField placeholder: 'Aufgaben filtern...'.

	choreList := self newTable.

	(debugMode notNil and: [ debugMode ]) ifTrue: [
		choreList addColumn: self idColumn ].

	choreList
		addColumn: self nameColumn;
		addColumn: self dateColumn;
		addColumn: self statusColumn.

	refreshButton := self newButton.
	refreshButton label: 'Aufgaben laden'.
	refreshButton icon: (self iconNamed: #refresh).

	statusLabel := self newLabel.
	statusLabel label: 'Noch keine Aufgaben geladen.'
]

{ #category : 'initialization' }
GrocyChoreBrowser >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'Grocy Chores Browser';
		initialExtent: 425 @ 350;
		"Sobald das Fenster geschlossen wird, killen wir den Timer-Prozess"whenClosedDo: [ self stopAutoRefreshTimer ].

	"Sofort beim Öffnen den Timer starten"
	self startAutoRefreshTimer
]

{ #category : 'initialization' }
GrocyChoreBrowser >> nameColumn [
	^ (SpStringTableColumn title: 'Aufgabe' evaluated: [ :chore | chore name ])
		beSortable
]

{ #category : 'updating' }
GrocyChoreBrowser >> refreshChoreList [
	[
		allChores := client getChores.

		"Sorgt dafür, dass das UI sicher aus dem Hintergrund-Thread geupdated wird"
		UIManager default defer: [
			self updateFilteredList.
			self updateStatistics ]
	] on: Error do: [ :err |
		UIManager default defer: [
			self inform: 'Fehler beim Laden: ', err messageText ] ]
]

{ #category : 'displaying' }
GrocyChoreBrowser >> sendOSNotificationTitle: titleString message: messageString [

	| platform rawScript bytes base64Script |
	platform := OSPlatform current.
	platform isMacOS ifTrue: [
			LibC runCommand: ('osascript -e ''display notification "{1}" with title "{2}"''' format: {
						 messageString.
						 titleString }).
			^ self ].
	platform isWindows ifTrue: [
			rawScript := '[void][System.Reflection.Assembly]::LoadWithPartialName(''System.Windows.Forms''); '
			             , '$icon = New-Object System.Windows.Forms.NotifyIcon; '
			             , '$icon.Icon = [System.Drawing.SystemIcons]::Information; ' , '$icon.Visible = $true; '
			             , '$icon.ShowBalloonTip(5000, ''{1}'', ''{2}'', ''Info''); ' , 'Start-Sleep -Seconds 4;'.
			rawScript := rawScript format: {
					             titleString.
					             messageString }.
			bytes := (ZnCharacterEncoder newForEncoding: #utf16le) encodeString: rawScript.
			base64Script := ZnBase64Encoder new encode: bytes.
			LibC runCommand: 'powershell -WindowStyle Hidden -EncodedCommand ' , base64Script.
			^ self ].
	platform isUnix ifFalse: [ ^ self ].
	LibC runCommand: ('notify-send "{1}" "{2}"' format: {
				 titleString.
				 messageString }).
	^ self
]

{ #category : 'updating' }
GrocyChoreBrowser >> skipSelectedChore [
	choreList selectedItem ifNotNil: [ :chore |
		[
			client skipChoreId: chore id.
			self refreshChoreList.

			self inform: ('Aufgabe "{1}" übersprungen.' format: { chore name }).
		] on: Error do: [ :err |
			self inform: 'Fehler beim Überspringen: ', err messageText ] ]
]

{ #category : 'updating' }
GrocyChoreBrowser >> startAutoRefreshTimer [
	"Falls schon ein Timer läuft, stoppen wir ihn zuerst"
	self stopAutoRefreshTimer.

	timerProcess := [
		[ true ] whileTrue: [
			"Wartezeit in Sekunden (z.B. 300 für 5 Minuten. Zum Testen gehen auch 30)"
			300 seconds wait.
			self refreshChoreList.
		]
	] forkAt: Processor userBackgroundPriority named: 'GrocyChoreBrowser-Timer'
]

{ #category : 'initialization' }
GrocyChoreBrowser >> statusColumn [
	"Da diese Spalte mit den Präfixen [!], [-], [/], [+] beginnt, sortiert sie sich"

	"alphabetisch absolut perfekt: Überfällige Aufgaben springen direkt nach oben!"

	^ (SpStringTableColumn title: 'Status / Tage' evaluated: [ :chore | self statusTextFor: chore ]) beSortable
]

{ #category : 'displaying' }
GrocyChoreBrowser >> statusTextFor: aChore [

	| tage ergebnis |
	tage := aChore daysRemaining.
	ergebnis := nil.

	tage < 0 ifTrue: [ ergebnis := '[!] ÜBERFÄLLIG' ].
	tage = 0 ifTrue: [ ergebnis := '[-] Heute' ].
	tage = 1 ifTrue: [ ergebnis := '[/] Morgen' ].
	tage > 100 ifTrue: [ ergebnis := '[?] Kein Datum' ].

	ergebnis ifNil: [ ergebnis := '[+] ' , tage asString , ' Tage' ].
	^ ergebnis
]

{ #category : 'updating' }
GrocyChoreBrowser >> stopAutoRefreshTimer [
	"Stoppt den Hintergrund-Prozess, wenn das Fenster geschlossen wird"
	timerProcess ifNotNil: [
		timerProcess terminate.
		timerProcess := nil ]
]

{ #category : 'updating' }
GrocyChoreBrowser >> updateFilteredList [

	| query filtered |
	query := searchField text trimBoth asLowercase.

	query isEmpty
		ifTrue: [ choreList items: allChores ]
		ifFalse: [
			filtered := allChores select: [ :chore |
				chore name asLowercase includesSubstring: query ].
			choreList items: filtered ]
]

{ #category : 'updating' }
GrocyChoreBrowser >> updateStatistics [

	| ueberfaellig heute morgen gesamt text |
	gesamt := allChores size.
	ueberfaellig := (allChores select: [ :c | c daysRemaining < 0 ]) size.
	heute := (allChores select: [ :c | c daysRemaining = 0 ]) size.
	morgen := (allChores select: [ :c | c daysRemaining = 1 ]) size.

	"Text für die untere Leiste updaten"
	text := 'Gesamt: {1} | [!] Überfällig: {2} | [-] Heute: {3} | [/] Morgen: {4}'
		format: { gesamt . ueberfaellig . heute . morgen }.
	statusLabel label: text.

	allChores do: [ :chore |
		(chore daysRemaining < 0 and: [ (notifiedChoreIds includes: chore id) not ]) ifTrue: [
			notifiedChoreIds add: chore id.
			self
				sendOSNotificationTitle: 'Grocy Aufgabe Überfällig!'
				message: ('Die Aufgabe "{1}" hätte erledigt werden müssen.' format: { chore name }) ] ]
]
