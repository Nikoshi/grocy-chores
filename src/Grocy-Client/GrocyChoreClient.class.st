"
A client that is used to get pending chores
"
Class {
	#name : 'GrocyChoreClient',
	#superclass : 'Object',
	#instVars : [
		'apiUrl',
		'apiKey'
	],
	#classVars : [
		'DefaultApiKey'
	],
	#category : 'Grocy-Client-Base',
	#package : 'Grocy-Client',
	#tag : 'Base'
}

{ #category : 'initialization' }
GrocyChoreClient class >> defaultApiKey [
	^ DefaultApiKey
]

{ #category : 'initialization' }
GrocyChoreClient class >> defaultApiKey: aString [
	DefaultApiKey := aString
]

{ #category : 'accessing' }
GrocyChoreClient >> apiKey: aString [
	apiKey := aString
]

{ #category : 'accessing' }
GrocyChoreClient >> apiUrl: aString [
	apiUrl := aString
]

{ #category : 'initialization' }
GrocyChoreClient >> buildProductCache [

	| productsJson cache |
	productsJson := STONJSON fromString: (ZnClient new
		url: (self objectsApiUrl , 'objects/products');
		headerAt: 'grocy-api-key' put: apiKey;
		get).

	cache := Dictionary new.
	productsJson do: [ :prod |
		cache at: (prod at: 'id') put: (prod at: 'name') ].
	^ cache
]

{ #category : 'removing' }
GrocyChoreClient >> clearShoppingList [
	"Da die Objects-API kein 'clear' kennt, löschen wir alle Einträge nacheinander"

	| aktuelleListe |
	aktuelleListe := self getShoppingList.
	aktuelleListe do: [ :item | self removeShoppingItemId: item id ]
]

{ #category : 'initialization' }
GrocyChoreClient >> completeTaskId: anInteger [
	"Markiert eine einmalige Aufgabe mit der geforderten Uhrzeit als erledigt"

	| targetUrl isoDateString jsonBody jsonEntity clientInstance |
	apiKey ifNil: [ self error: 'Missing API Key' ].
	targetUrl := (apiUrl copyReplaceAll: 'chores' with: 'tasks'), '/', anInteger asString, '/complete'.

	isoDateString := Date today yyyymmdd.
	jsonBody := '{"done_time": "', isoDateString, '"}'.

	jsonEntity := ZnEntity text: jsonBody.
	jsonEntity contentType: ZnMimeType applicationJson.

	clientInstance := ZnClient new.
	clientInstance
		url: targetUrl;
		headerAt: 'grocy-api-key' put: apiKey;
		entity: jsonEntity;
		post.

	clientInstance isSuccess ifFalse: [
		self error: 'Grocy API Fehler: ', clientInstance response statusLine asString ]
]

{ #category : 'initialization' }
GrocyChoreClient >> executeChoreId: anInteger [
	"Meldet die Aufgabe mit der korrekten Grocy-Payload als erledigt"
	self
		postToChoreId: anInteger
		action: 'execute'
		jsonBody: '{"skipped": false, "done_by": null}'
]

{ #category : 'accessing' }
GrocyChoreClient >> getChores [

	| jsonArray |
	apiKey ifNil: [ self error: 'Missing API Key' ].

	jsonArray := STONJSON fromString: (ZnClient new
		url: apiUrl;
		headerAt: 'grocy-api-key' put: apiKey;
		get).

	^ jsonArray collect: [ :each |
		GrocyChore new
			id: (each at: 'chore_id')
			name: (each at: 'chore_name')
			nextExecution: (each at: 'next_estimated_execution_time') ]
]

{ #category : 'accessing' }
GrocyChoreClient >> getShoppingList [

	| shoppingJson productCache |
	apiKey ifNil: [ self error: 'Missing API Key' ].

	"1. Lokalen Cache über die Hilfsmethode aufbauen"
	productCache := self buildProductCache.

	"2. Einkaufsliste herunterladen"
	shoppingJson := STONJSON fromString: (ZnClient new
		url: (self objectsApiUrl , 'objects/shopping_list');
		headerAt: 'grocy-api-key' put: apiKey;
		get).

	"3. Einträge über die Mapping-Methode transformieren"
	^ shoppingJson collect: [ :each |
		self mapShoppingItem: each withCache: productCache ]
]

{ #category : 'accessing' }
GrocyChoreClient >> getTasks [

	| jsonArray |
	apiKey ifNil: [ self error: 'Missing API Key' ].

	jsonArray := STONJSON fromString: (ZnClient new
		url: ((apiUrl copyReplaceAll: 'chores' with: 'tasks'), '?status=open');
		headerAt: 'grocy-api-key' put: apiKey;
		get).

	^ jsonArray collect: [ :each |
		GrocyTask new
			id: (each at: 'id')
			name: (each at: 'name')
			dueDate: (each at: 'due_date') ]
]

{ #category : 'initialization' }
GrocyChoreClient >> initialize [
	super initialize.
	apiUrl := 'http://localhost:9283/api/chores'.
	apiKey := self class defaultApiKey
]

{ #category : 'initialization' }
GrocyChoreClient >> mapShoppingItem: each withCache: productCache [

	| itemId prodId prodName noteText itemAmount |
	itemId := each at: 'id'.
	itemAmount := each at: 'amount' ifAbsent: [ 1 ].
	noteText := each at: 'note' ifAbsent: [ nil ].

	prodId := each at: 'product_id' ifAbsent: [ nil ].
	prodName := prodId
		ifNil: [ nil ]
		ifNotNil: [ productCache at: prodId ifAbsent: [ 'Unbekanntes Produkt' ] ].

	^ GrocyShoppingItem new
		id: itemId
		productName: prodName
		amount: itemAmount
		note: noteText
]

{ #category : 'converting' }
GrocyChoreClient >> objectsApiUrl [
	"Schneidet /chores ab und liefert die Basis für die Objects-API"
	^ apiUrl copyFrom: 1 to: (apiUrl size - 6)
]

{ #category : 'accessing' }
GrocyChoreClient >> postToChoreId: anInteger action: actionString jsonBody: jsonString [

	| targetUrl jsonEntity clientInstance |
	apiKey ifNil: [ self error: 'Missing API Key' ].

	targetUrl := apiUrl, '/', anInteger asString, '/', actionString.

	jsonEntity := ZnEntity text: jsonString.
	jsonEntity contentType: ZnMimeType applicationJson.

	clientInstance := ZnClient new.
	clientInstance
		url: targetUrl;
		headerAt: 'grocy-api-key' put: apiKey;
		entity: jsonEntity;
		post.

	"Wenn Grocy nicht mit 200/204 antwortet, wirft Pharo jetzt einen sichtbaren Fehler"
	clientInstance isSuccess ifFalse: [
		self error: 'Grocy API Fehler: ', clientInstance response statusLine asString ]
]

{ #category : 'removing' }
GrocyChoreClient >> removeShoppingItemId: anInteger [
	"Generische Objekte werden in Grocy über einen DELETE-Request gelöscht"

	| targetUrl |
	apiKey ifNil: [ self error: 'Missing API Key' ].
	
	"Baut z.B. http://localhost:9283/api/objects/shopping_list/31"
	targetUrl := (apiUrl copyFrom: 1 to: (apiUrl size - 6)), 'objects/shopping_list/', anInteger asString.

	ZnClient new
		url: targetUrl;
		headerAt: 'grocy-api-key' put: apiKey;
		delete "Führt den echten HTTP DELETE Befehl aus"

]

{ #category : 'initialization' }
GrocyChoreClient >> skipChoreId: anInteger [
	"Überspringt die Aufgabe mit der korrekten Grocy-Payload"
	self
		postToChoreId: anInteger
		action: 'execute'
		jsonBody: '{"skipped": true, "done_by": null}'
]
