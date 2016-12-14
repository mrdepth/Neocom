//
//  NCStorageExtensions.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import CoreData

extension NCAccount {
	
	@nonobjc static var current: NCAccount? = {
		guard let url = UserDefaults.standard.url(forKey: UserDefaults.Key.NCCurrentAccount) else {return nil}
		guard let objectID = NCStorage.sharedStorage?.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) else {return nil}
		return (try? NCStorage.sharedStorage?.viewContext.existingObject(with: objectID)) as? NCAccount
		}() {
		didSet {
			NotificationCenter.default.post(name: .NCCurrentAccountChanged, object: current)
			if let objectID = current?.objectID {
				UserDefaults.standard.set(objectID.uriRepresentation(), forKey: UserDefaults.Key.NCCurrentAccount)
			}
			else {
				UserDefaults.standard.removeObject(forKey: UserDefaults.Key.NCCurrentAccount)
			}
		}
	}

	var token: OAuth2Token {
		get {
			let scopes = (self.scopes as? Set<NCScope>)!.map {
				return $0.name!
			}
			
			let token = OAuth2Token(accessToken: accessToken!, refreshToken: refreshToken!, tokenType: tokenType!, scopes: scopes, characterID: characterID, characterName: characterName!, realm: realm!)
			token.expiresOn = expiresOn! as Date
			return token
		}
		set {
			let token = newValue
			if accessToken != token.accessToken {accessToken = token.accessToken}
			if refreshToken != token.refreshToken {refreshToken = token.refreshToken}
			if tokenType != token.tokenType {tokenType = token.tokenType}
			if characterID != token.characterID {characterID = token.characterID}
			if characterName != token.characterName {characterName = token.characterName}
			if realm != token.realm {realm = token.realm}
			if let expiresOn = token.expiresOn as NSDate?, expiresOn != self.expiresOn {
				self.expiresOn = expiresOn
			}
			let newScopes = Set<String>(token.scopes)
			
			let toInsert: Set<String>
			if let scopes = self.scopes as? Set<NCScope> {
				let toDelete = scopes.filter {
					return !newScopes.contains($0.name!)
				}
				for scope in toDelete {
					managedObjectContext!.delete(scope)
				}
				toInsert = newScopes.symmetricDifference(scopes.map {return $0.name!})
			}
			else {
				toInsert = newScopes
			}
			
			for name in toInsert {
				let scope = NCScope(entity: NSEntityDescription.entity(forEntityName: "Scope", in: managedObjectContext!)!, insertInto: managedObjectContext!)
				scope.name = name
				scope.account = self
			}

		}
	}
	
}
