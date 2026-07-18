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
		'notifiedChoreIds',
		'notebook',
		'taskList',
		'allTasks',
		'shoppingListTable',
		'allShoppingItems'
	],
	#category : 'Grocy-Client-Base',
	#package : 'Grocy-Client',
	#tag : 'Base'
}

{ #category : 'layout' }
GrocyChoreBrowser class >> defaultLayout [
    ^ SpBoxLayout newVertical
        spacing: 5;
        add: #searchField expand: false;
        add: #notebook;
        add: #refreshButton expand: false;
        add: #statusLabel expand: false;
        yourself
]

{ #category : 'world menu' }
GrocyChoreBrowser class >> menuCommandOn: aBuilder [

    <worldMenu>
    (aBuilder item: #GrocyHaushaltsZentrale)
        order: 200;
        label: 'Grocy';
        icon: (self iconNamed: #home);
        help: 'Öffnet den Grocy Manager';
        action: [ self new open ]
]

{ #category : 'actions' }
GrocyChoreBrowser >> clearWholeShoppingList [
    (UIManager default confirm: 'Möchtest du die Einkaufsliste wirklich komplett leeren?') ifTrue: [
        [
            [
                client clearShoppingList.
                self refreshChoreList.
                UIManager default defer: [
                    self inform: 'Einkaufsliste wurde komplett geleert!' ].
            ] on: Error do: [ :err |
                UIManager default defer: [
                    self inform: 'Fehler: ', err messageText ] ]
        ] forkAt: Processor userBackgroundPriority named: 'Grocy-ClearShoppingList' ]
]

{ #category : 'actions' }
GrocyChoreBrowser >> completeSelectedTask [
    taskList selectedItem ifNotNil: [ :task |
        [
            [
                client completeTaskId: task id.
                self refreshChoreList.
                UIManager default defer: [
                    self inform: ('To-Do "{1}" erfolgreich abgeschlossen!' format: { task name }) ].
            ] on: Error do: [ :err |
                UIManager default defer: [
                    self inform: 'Fehler: ', err messageText ] ]
        ] forkAt: Processor userBackgroundPriority named: 'Grocy-CompleteTask' ]
]

{ #category : 'initialization' }
GrocyChoreBrowser >> connectPresenters [

    refreshButton action: [ self refreshChoreList ].
    searchField whenTextChangedDo: [ :text | self updateFilteredList ].

    choreList contextMenu: self createContextMenu.
    taskList contextMenu: (self newMenu addItem: [ :item |
                 item
                     name: 'Als erledigt markieren';
                     icon: (self iconNamed: #testGreen);
                     action: [ self completeSelectedTask ] ]).

    shoppingListTable contextMenu: self createShoppingContextMenu
]

{ #category : 'private - factory' }
GrocyChoreBrowser >> createContextMenu [
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

{ #category : 'private - factory' }
GrocyChoreBrowser >> createShoppingContextMenu [
    ^ self newMenu
          addItem: [ :item |
                  item
                      name: 'Artikel von Liste entfernen';
                      icon: (self iconNamed: #delete);
                      action: [ self removeSelectedShoppingItem ] ];
          addItem: [ :item |
                  item
                      name: 'KOMPLETTE LISTE LEEREN';
                      icon: (self iconNamed: #remove);
                      action: [ self clearWholeShoppingList ] ]
]

{ #category : 'private - factory' }
GrocyChoreBrowser >> dateColumn [
    ^ (SpStringTableColumn title: 'Fällig am' evaluated: [ :chore | self formatDateString: chore nextExecution ])
        beSortable
]

{ #category : 'accessing' }
GrocyChoreBrowser >> debugMode [

	^ debugMode ifNil: [ debugMode := false ]
]

{ #category : 'actions' }
GrocyChoreBrowser >> executeSelectedChore [
    choreList selectedItem ifNotNil: [ :chore |
        [
            [
                client executeChoreId: chore id.
                notifiedChoreIds remove: chore id ifAbsent: [ ].
                self refreshChoreList.
                UIManager default defer: [
                    self inform: ('Aufgabe "{1}" erfolgreich erledigt!' format: { chore name }) ].
            ] on: Error do: [ :err |
                UIManager default defer: [
                    self inform: 'Fehler beim Erledigen: ', err messageText ] ]
        ] forkAt: Processor userBackgroundPriority named: 'Grocy-ExecuteChore' ]
]

{ #category : 'private' }
GrocyChoreBrowser >> formatDateString: anObject [
    anObject ifNil: [ ^ 'Kein Datum' ].
    ^ anObject asString size >= 10
        ifTrue: [ anObject asString copyFrom: 1 to: 10 ]
        ifFalse: [ anObject asString ]
]

{ #category : 'private - factory' }
GrocyChoreBrowser >> idColumn [
    ^ (SpStringTableColumn title: 'ID' evaluated: [ :chore | chore id asString ])
        beSortable
]

{ #category : 'initialization' }
GrocyChoreBrowser >> initialize [

	| gespeicherteUrl gespeicherterKey eingabe |
	super initialize.
	allChores := OrderedCollection new.
	allTasks := OrderedCollection new.
	allShoppingItems := OrderedCollection new.
	notifiedChoreIds := Set new.

	gespeicherteUrl := GrocyChoreClient defaultApiUrl.

	gespeicherteUrl ifNil: [
		eingabe := UIManager default request: 'ERSTER START: API-URL BENÖTIGT

Bitte gib deine Grocy API-URL ein:'.
		(eingabe notNil and: [ eingabe trimBoth isNotEmpty ]) ifTrue: [
			GrocyChoreClient defaultApiUrl: eingabe trimBoth.
			gespeicherteUrl := eingabe trimBoth ] ].

	gespeicherterKey := GrocyChoreClient defaultApiKey.

	gespeicherterKey ifNil: [
			eingabe := UIManager default request: 'ERSTER START: API-KEY BENÖTIGT

Bitte gib deinen Grocy API-Key ein:'.

			(eingabe notNil and: [ eingabe trimBoth isNotEmpty ]) ifTrue: [
					GrocyChoreClient defaultApiKey: eingabe trimBoth.
					gespeicherterKey := eingabe trimBoth ] ].

	client := GrocyChoreClient new.
	client apiKey: gespeicherterKey.
	client baseUrl: gespeicherteUrl
]

{ #category : 'initialization' }
GrocyChoreBrowser >> initializePresenters [

	searchField := self newTextInput.
	searchField placeholder: 'Einträge, Aufgaben oder To-Dos filtern...'.

	choreList := self newTable.
	self debugMode ifTrue: [ choreList addColumn: self idColumn ].
	choreList
		addColumn: self nameColumn;
		addColumn: self dateColumn;
		addColumn: self statusColumn.

	taskList := self newTable.
	debugMode ifTrue: [ taskList addColumn: (SpStringTableColumn title: 'ID' evaluated: [ :task | task id asString ]) beSortable ].
	taskList
		addColumn: (SpStringTableColumn title: 'To-Do' evaluated: [ :task | task name ]) beSortable;
		addColumn: (SpStringTableColumn title: 'Fällig am' evaluated: [ :task | self formatDateString: task dueDate ]) beSortable;
		addColumn: (SpStringTableColumn title: 'Status' evaluated: [ :task | self statusTextFor: task ]) beSortable.

	shoppingListTable := self newTable.
	debugMode ifTrue: [
		shoppingListTable addColumn: (SpStringTableColumn title: 'ID' evaluated: [ :item | item id asString ]) beSortable ].
	shoppingListTable
		addColumn: (SpStringTableColumn title: 'Eintrag / Produkt' evaluated: [ :item | item displayName ]) beSortable;
		addColumn: (SpStringTableColumn title: 'Menge' evaluated: [ :item | item amount asString ]) beSortable.

	notebook := self newNotebook.
	notebook
		addPage: (SpNotebookPage title: 'Wiederkehrend (Chores)' icon: (self iconNamed: #calendar) provider: [ choreList ]);
		addPage: (SpNotebookPage title: 'Einmalig (Tasks)' icon: (self iconNamed: #checkboxSelected) provider: [ taskList ]);
		addPage: (SpNotebookPage title: 'Einkaufsliste' icon: (self iconNamed: #book) provider: [ shoppingListTable ]).

	refreshButton := self newButton.
	refreshButton label: 'Alles aktualisieren / Synchronisieren'.
	refreshButton icon: (self iconNamed: #refresh).

	statusLabel := self newLabel.
	statusLabel label: 'Noch keine Daten geladen.'
]

{ #category : 'initialization' }
GrocyChoreBrowser >> initializeWindow: aWindow [

    super initializeWindow: aWindow.
    aWindow
        title: 'Grocy Manager';
        initialExtent: 550 @ 500;
        whenClosedDo: [ self stopAutoRefreshTimer ].

    self registerHotReload: aWindow.

    self startAutoRefreshTimer.
    [ self refreshChoreList ] forkAt: Processor userBackgroundPriority named: 'Grocy-InitialSync'
]

{ #category : 'private - factory' }
GrocyChoreBrowser >> nameColumn [
    ^ (SpStringTableColumn title: 'Aufgabe' evaluated: [ :chore | chore name ])
        beSortable
]

{ #category : 'actions' }
GrocyChoreBrowser >> refreshChoreList [
    [
        "Chores nach verbleibenden Tagen aufsteigend sortieren"
        allChores := client getChores sorted: [ :a :b |
            a daysRemaining <= b daysRemaining ].

        "Tasks nach Datum aufsteigend sortieren (Tasks ohne Datum ans Ende)"
        allTasks := client getTasks sorted: [ :a :b |
            a dueDate
                ifNil: [ false ]
                ifNotNil: [
                    b dueDate
                        ifNil: [ true ]
                        ifNotNil: [ a dueDate <= b dueDate ] ] ].

        allShoppingItems := client getShoppingList.

        UIManager default defer: [
            self updateFilteredList.
            self updateStatistics ]
    ] on: Error do: [ :err |
        UIManager default defer: [
            self inform: 'Fehler beim Laden: ', err messageText ] ]
]

{ #category : 'initialization' }
GrocyChoreBrowser >> registerHotReload: aWindow [
    aWindow bindKeyCombination: $r control | $r command
        toAction: [
            | realistischesFenster altePosition alteGroesse neuesPresenter |
            self inform: 'Hot-Reloading UI...'.

            realistischesFenster := aWindow window.
            altePosition := realistischesFenster position.
            alteGroesse := realistischesFenster bounds extent.

            aWindow close.

            neuesPresenter := self class new.
            neuesPresenter open.
            neuesPresenter window window
                position: altePosition;
                extent: alteGroesse ]
]

{ #category : 'actions' }
GrocyChoreBrowser >> removeSelectedShoppingItem [
    shoppingListTable selectedItem ifNotNil: [ :item |
        [
            [
                client removeShoppingItemId: item id.
                self refreshChoreList.
                UIManager default defer: [
                    self inform: ('"{1}" von Einkaufsliste entfernt.' format: { item displayName }) ].
            ] on: Error do: [ :err |
                UIManager default defer: [
                    self inform: 'Fehler: ', err messageText ] ]
        ] forkAt: Processor userBackgroundPriority named: 'Grocy-RemoveShoppingItem' ]
]

{ #category : 'private' }
GrocyChoreBrowser >> sendOSNotificationTitle: titleString message: messageString [
    [
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
            rawScript := rawScript format: { titleString. messageString }.
            bytes := (ZnCharacterEncoder newForEncoding: #utf16le) encodeString: rawScript.
            base64Script := ZnBase64Encoder new encode: bytes.
            LibC runCommand: 'powershell -WindowStyle Hidden -EncodedCommand ' , base64Script.
            ^ self ].
        platform isUnix ifTrue: [
            LibC runCommand: ('notify-send "{1}" "{2}"' format: { titleString. messageString }) ]
    ] forkAt: Processor userBackgroundPriority named: 'Grocy-OSNotification'
]

{ #category : 'actions' }
GrocyChoreBrowser >> skipSelectedChore [
    choreList selectedItem ifNotNil: [ :chore |
        [
            [
                client skipChoreId: chore id.
                self refreshChoreList.
                UIManager default defer: [
                    self inform: ('Aufgabe "{1}" übersprungen.' format: { chore name }) ].
            ] on: Error do: [ :err |
                UIManager default defer: [
                    self inform: 'Fehler beim Überspringen: ', err messageText ] ]
        ] forkAt: Processor userBackgroundPriority named: 'Grocy-SkipChore' ]
]

{ #category : 'actions - timer' }
GrocyChoreBrowser >> startAutoRefreshTimer [
    self stopAutoRefreshTimer.

    timerProcess := [
        [ true ] whileTrue: [
            300 seconds wait.
            self refreshChoreList.
        ]
    ] forkAt: Processor userBackgroundPriority named: 'GrocyChoreBrowser-Timer'
]

{ #category : 'private - factory' }
GrocyChoreBrowser >> statusColumn [
    ^ (SpStringTableColumn title: 'Status / Tage' evaluated: [ :chore | self statusTextFor: chore ]) beSortable
]

{ #category : 'private' }
GrocyChoreBrowser >> statusTextFor: aChore [

    | tage |
    tage := aChore daysRemaining.

    tage < 0 ifTrue: [ ^ '[!] ÜBERFÄLLIG' ].
    tage = 0 ifTrue: [ ^ '[-] Heute' ].
    tage = 1 ifTrue: [ ^ '[/] Morgen' ].
    tage > 100 ifTrue: [ ^ '[?] Kein Datum' ].

    ^ '[+] ' , tage asString , ' Tage'
]

{ #category : 'actions - timer' }
GrocyChoreBrowser >> stopAutoRefreshTimer [
    timerProcess ifNotNil: [
        timerProcess terminate.
        timerProcess := nil ]
]

{ #category : 'private' }
GrocyChoreBrowser >> updateFilteredList [

    | query filteredChores filteredTasks filteredItems |
    query := searchField text trimBoth asLowercase.

    query isEmpty
        ifTrue: [
            choreList items: allChores.
            taskList items: allTasks.
            shoppingListTable items: allShoppingItems ]
        ifFalse: [
            filteredChores := allChores select: [ :c | c name asLowercase includesSubstring: query ].
            filteredTasks := allTasks select: [ :t | t name asLowercase includesSubstring: query ].
            filteredItems := allShoppingItems select: [ :i | i displayName asLowercase includesSubstring: query ].
            choreList items: filteredChores.
            taskList items: filteredTasks.
            shoppingListTable items: filteredItems ]
]

{ #category : 'private' }
GrocyChoreBrowser >> updateStatistics [

    | ueberfaellig heute morgen gesamt text |
    gesamt := allChores size.
    ueberfaellig := (allChores select: [ :c | c daysRemaining < 0 ]) size.
    heute := (allChores select: [ :c | c daysRemaining = 0 ]) size.
    morgen := (allChores select: [ :c | c daysRemaining = 1 ]) size.

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
