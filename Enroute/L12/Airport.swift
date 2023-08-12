//
//  Airport.swift
//  Enroute
//
//  Created by Treata Norouzi on 8/11/23.
//

import Combine
import CoreData

extension Airport: Comparable {
    static func withICAO(_ icao: String, context: NSManagedObjectContext ) -> Airport {
        // look-up the icao in Core Data
        let request = fetchRequest(NSPredicate(format: "icao_ = %@", icao))
        /* capable of pattern-matching, begins-with ... */
        let airports = (try? context.fetch(request)) ?? [] // do-catch
        if let airport = airports.first {
            // if found, return it
            return airport
        } else {
            // if not, create one and fetch from FA
            let airport = Airport(context: context)
            airport.icao = icao
            AirportInfoRequest.fetch(icao) { airportInfo in
                // This func nested in the other func is going to happen asynchronously
                // the action of fetching/looking/updating from a DB has to take place on some other thread
                update(from: airportInfo, context: context)
            }
            return airport
        }
    }
    
    static func update(from info: AirportInfo, context: NSManagedObjectContext) {
        if let icao = info.icao {
            let airport = self.withICAO(icao, context: context)
            airport.latitude = info.latitude
            airport.longitude = info.longitude
            airport.name = info.name
            airport.location = info.location
            airport.timezone = info.timezone
            airport.objectWillChange.send()
            airport.flightsTo.forEach { $0.objectWillChange.send() }
            airport.flightsFrom.forEach { $0.objectWillChange.send() }
            /*
             The value of a relationship var that is a to-many var is a NSSet of it's destination!
             Not any of swift's collection types, not a casual Set<T>
             */
            try? context.save() // save the changes to the DB
        }
    }
    
    // MARK: - Side Syntactic Sugar
    
    var flightsTo: Set<Flight> {
        get { (flightsTo_ as? Set<Flight>) ?? [] }
        set { flightsTo_ = newValue as NSSet }
    }
    var flightsFrom: Set<Flight> {
        get { (flightsFrom_ as? Set<Flight>) ?? [] }
        set { flightsFrom_ = newValue as NSSet }
    }
    
    func fetchIncomingFlights() {
        Self.flightAwareRequest?.stopFetching()
        if let context = managedObjectContext { // asking the Airport obj what context you came out of
            /* when you have an instance from the DB at your hand, you can always see the context it came out from */
            Self.flightAwareRequest = EnrouteRequest.create(airport: icao, howMany: 90)
            Self.flightAwareRequest?.fetch(andRepeatEvery: 60)
            Self.flightAwareResultsCancellable = Self.flightAwareRequest?.results.sink { results in
                for faflight in results {
                    Flight.update(from: faflight, in: context)
                }
                do {
                    try context.save()
                } catch(let error) {
                    print("couldn't save flight update to CoreData: \(error.localizedDescription)")
                }
            }
        }
    }

    private static var flightAwareRequest: EnrouteRequest!
    private static var flightAwareResultsCancellable: AnyCancellable?
    
    var icao: String {
        get { icao_! } // TODO: maybe protect against when app ships?
        set { icao_ = newValue }
    }

    var friendlyName: String {
        let friendly = AirportInfo.friendlyName(name: self.name ?? "", location: self.location ?? "")
        return friendly.isEmpty ? icao : friendly
    }

    public var id: String { icao }

    public static func < (lhs: Airport, rhs: Airport) -> Bool {
        lhs.location ?? lhs.friendlyName < rhs.location ?? rhs.friendlyName
    }
    
    static func fetchRequest(_ predicate: NSPredicate) -> NSFetchRequest<Airport> {
        let request = NSFetchRequest<Airport>(entityName: "Airport")
        request.sortDescriptors = [NSSortDescriptor(key: "location", ascending: true)]
        request.predicate = predicate
        return request
    }
}
