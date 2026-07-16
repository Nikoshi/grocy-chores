"
Simple serialized Task class from grocy
"
Class {
	#name : 'GrocyTask',
	#superclass : 'Object',
	#instVars : [
		'id',
		'name',
		'dueDate',
		'status'
	],
	#category : 'Grocy-Client-Base',
	#package : 'Grocy-Client',
	#tag : 'Base'
}

{ #category : 'accessing' }
GrocyTask >> daysRemaining [

	| targetDate |
	dueDate ifNil: [ ^ 999 ].
	dueDate size < 10 ifTrue: [ ^ 999 ].
	targetDate := (dueDate copyFrom: 1 to: 10) asDate.
	^ targetDate subtractDate: Date today
]

{ #category : 'accessing' }
GrocyTask >> dueDate [
	^ dueDate
]

{ #category : 'accessing' }
GrocyTask >> id [
	^ id
]

{ #category : 'accessing' }
GrocyTask >> id: anInteger name: aString dueDate: aDateTimeString [
	id := anInteger.
	name := aString.
	dueDate := aDateTimeString
]

{ #category : 'accessing' }
GrocyTask >> name [
	^ name
]
