Class {
	#name : 'GrocyChoreClient',
	#superclass : 'Object',
	#instVars : [
		'baseUrl',
		'apiKey',
		'httpClient',
		'productCache'
	],
	#classVars : [
		'DefaultApiKey'
	],
	#category : 'Grocy-Client-Base',
	#package : 'Grocy-Client',
	#tag : 'Base'
}

{ #category : 'accessing' }
GrocyChoreClient class >> defaultApiKey [
    ^ DefaultApiKey
]

{ #category : 'accessing' }
GrocyChoreClient class >> defaultApiKey: aString [
    DefaultApiKey := aString
]

{ #category : 'accessing' }
GrocyChoreClient >> apiKey: aString [
    apiKey := aString.
    httpClient ifNotNil: [ 
        httpClient headerAt: 'grocy-api-key' put: apiKey ]
]

{ #category : 'accessing' }
GrocyChoreClient >> baseUrl [
    ^ baseUrl
]

{ #category : 'accessing' }
GrocyChoreClient >> baseUrl: aString [
    baseUrl := aString
]

{ #category : 'private' }
GrocyChoreClient >> buildProductCache [

    | productsJson |
    productCache ifNotNil: [ ^ productCache ].

    productsJson := STONJSON fromString: (httpClient
        url: (self baseUrl , '/objects/products');
        get).

    productCache := Dictionary new.
    productsJson do: [ :prod |
        productCache at: (prod at: 'id') put: (prod at: 'name') ].
    
    ^ productCache
]

{ #category : 'api - actions' }
GrocyChoreClient >> clearShoppingList [

    | aktuelleListe |
    aktuelleListe := self getShoppingList.
    aktuelleListe do: [ :item | self removeShoppingItemId: item id ]
]

{ #category : 'api - actions' }
GrocyChoreClient >> completeTaskId: anInteger [

    | targetUrl payload |
    targetUrl := self baseUrl, '/tasks/', anInteger asString, '/complete'.
    
    "Datum im Format YYYY-MM-DD"
    payload := { 'done_time' -> (Date today printFormat: #(3 2 1 $- 1 1 2)) } asDictionary.
    
    self postUrl: targetUrl jsonDictionary: payload
]

{ #category : 'api - actions' }
GrocyChoreClient >> executeChoreId: anInteger [

    self
        postToChoreId: anInteger
        action: 'execute'
        jsonDictionary: { 'skipped' -> false . 'done_by' -> nil } asDictionary
]

{ #category : 'api - accessing' }
GrocyChoreClient >> getChores [

    | jsonArray |
    jsonArray := STONJSON fromString: (httpClient
        url: (self baseUrl, '/chores');
        get).

    ^ jsonArray collect: [ :each |
        GrocyChore new
            id: (each at: 'chore_id')
            name: (each at: 'chore_name')
            nextExecution: (each at: 'next_estimated_execution_time') ]
]

{ #category : 'api - accessing' }
GrocyChoreClient >> getShoppingList [

    | shoppingJson cache |
    cache := self buildProductCache.

    shoppingJson := STONJSON fromString: (httpClient
        url: (self baseUrl , '/objects/shopping_list');
        get).

    ^ shoppingJson collect: [ :each |
        self mapShoppingItem: each withCache: cache ]
]

{ #category : 'api - accessing' }
GrocyChoreClient >> getTasks [

    | jsonArray |
    jsonArray := STONJSON fromString: (httpClient
        url: (self baseUrl, '/tasks?status=open');
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
    baseUrl := 'http://localhost:9283/api'.
    
    httpClient := ZnClient new.
    httpClient enforceHttpSuccess: true. "Wirft ZnHttpUnsuccessful bei 4xx/5xx"
    
    self class defaultApiKey ifNotNil: [ :key | self apiKey: key ]
]

{ #category : 'api - actions' }
GrocyChoreClient >> invalidateProductCache [
    "Leert den Cache, damit er beim nächsten Aufruf neu von der API geladen wird"
    productCache := nil
]

{ #category : 'private' }
GrocyChoreClient >> mapShoppingItem: each withCache: cache [

    | itemId prodId prodName noteText itemAmount |
    itemId := each at: 'id'.
    itemAmount := each at: 'amount' ifAbsent: [ 1 ].
    noteText := each at: 'note' ifAbsent: [ nil ].

    prodId := each at: 'product_id' ifAbsent: [ nil ].
    prodName := prodId
        ifNil: [ nil ]
        ifNotNil: [ cache at: prodId ifAbsent: [ 'Unbekanntes Produkt' ] ].

    ^ GrocyShoppingItem new
        id: itemId
        productName: prodName
        amount: itemAmount
        note: noteText
]

{ #category : 'private' }
GrocyChoreClient >> postToChoreId: anInteger action: actionString jsonDictionary: aDictionary [

    | targetUrl |
    targetUrl := self baseUrl, '/chores/', anInteger asString, '/', actionString.
    self postUrl: targetUrl jsonDictionary: aDictionary
]

{ #category : 'private' }
GrocyChoreClient >> postUrl: urlString jsonDictionary: aDictionary [
    "Generische POST-Methode, die saubere JSON-Bodies erzeugt und den Status des Clients aufräumt"

    | jsonEntity |
    jsonEntity := ZnEntity text: (STONJSON toString: aDictionary).
    jsonEntity contentType: ZnMimeType applicationJson.

    httpClient
        url: urlString;
        entity: jsonEntity;
        post;
        entity: nil "Verhindert, dass die Entity bei Folge-Requests mitgeschickt wird"
]

{ #category : 'api - actions' }
GrocyChoreClient >> removeShoppingItemId: anInteger [

    httpClient
        url: (self baseUrl, '/objects/shopping_list/', anInteger asString);
        delete
]

{ #category : 'api - actions' }
GrocyChoreClient >> skipChoreId: anInteger [

    self
        postToChoreId: anInteger
        action: 'execute'
        jsonDictionary: { 'skipped' -> true . 'done_by' -> nil } asDictionary
]
