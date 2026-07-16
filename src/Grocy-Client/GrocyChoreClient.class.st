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

{ #category : 'initialization' }
GrocyChoreClient >> skipChoreId: anInteger [
	"Überspringt die Aufgabe mit der korrekten Grocy-Payload"
	self
		postToChoreId: anInteger
		action: 'execute'
		jsonBody: '{"skipped": true, "done_by": null}'
]
