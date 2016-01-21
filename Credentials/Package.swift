//
//  Package.swift
//  Credentials
//
//  Created by Ira Rosen on 21/1/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "Credentials",
    dependencies: [ .Package(url: "git@github.ibm.com:ibmswift/Phoenix.git", majorVersion: 0),
    ]
)
