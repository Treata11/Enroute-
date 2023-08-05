//
//  MapView.swift
//  Enroute
//
//  Created by Treata Norouzi on 8/5/23.
//  Copyright © 2023 Stanford University. All rights reserved.
//

import SwiftUI
import UIKit
import MapKit

struct MapView: UIViewRepresentable {
    let annotations: [MKAnnotation]
    @Binding var selection: MKAnnotation?
    
    func makeUIView(context: Context) -> MKMapView {
        let mkMapView = MKMapView()
        mkMapView.delegate = context.coordinator
        mkMapView.addAnnotations(annotations)
        return mkMapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Keep our UI up to date as SwiftUI goes through the reactive UI mechanism
        if let annotation = selection {
            let town = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            uiView.setRegion(MKCoordinateRegion(center: annotation.coordinate, span: town), animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        // This func creates the Coordinator for the context
        return Coordinator(selection: $selection)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        // The type is the delegate of self
        @Binding var selection: MKAnnotation?
        
        init(selection: Binding<MKAnnotation?>) {
            _selection = selection
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: "MapViewAnnotation") ??
                MKPinAnnotationView(annotation: annotation, reuseIdentifier: "MapViewAnnotation")
            view.canShowCallout = true
            return view
        }
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation {
                selection = annotation
            }
        }
    }
}
