//
//  EnrouteApp.swift
//  Enroute
//
//  Created by Treata Norouzi on 8/10/23.
//

import SwiftUI

@main
struct EnrouteApp: App {
    var airport: Airport {
        let airport_ = Airport.withICAO("KSFO", context: PersistenceController.shared.container.viewContext)
        airport_.fetchIncomingFlights()
        return airport_
    }
    
    
    var body: some Scene {
        WindowGroup {
            FlightsEnrouteView(flightSearch: FlightSearch(destination: airport))
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}
