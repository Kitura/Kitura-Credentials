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
        .Package(url: "git@github.ibm.com:ibmswift/PhoenixCurlHelpers.git", majorVersion: 1),
        .Package(url: "git@github.ibm.com:ibmswift/PhoenixHttpParserHelper.git", majorVersion: 1),
        .Package(url: "git@github.ibm.com:ibmswift/PhoenixPcre2.git", majorVersion: 1)
    ]
)
