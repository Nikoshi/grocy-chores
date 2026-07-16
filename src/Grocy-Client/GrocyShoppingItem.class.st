"
Simple serialized shopping list class
"
Class {
	#name : 'GrocyShoppingItem',
	#superclass : 'Object',
	#instVars : [
		'id',
		'productName',
		'amount',
		'note'
	],
	#category : 'Grocy-Client-Base',
	#package : 'Grocy-Client',
	#tag : 'Base'
}

{ #category : 'accessing' }
GrocyShoppingItem >> amount [
	^ amount
]

{ #category : 'accessing' }
GrocyShoppingItem >> displayName [
	"Prüft, ob ein echtes Produkt verknüpft ist. Falls nicht, wird die Notiz genutzt"

	productName ifNotNil: [ ^ productName ].
	note ifNotNil: [ ^ note ].
	^ 'Unbenannter Eintrag'
]

{ #category : 'accessing' }
GrocyShoppingItem >> id [
	^ id
]

{ #category : 'accessing' }
GrocyShoppingItem >> id: anInteger productName: aString amount: aNumber note: aNoteString [
	id := anInteger.
	productName := aString.
	amount := aNumber.
	note := aNoteString
]
