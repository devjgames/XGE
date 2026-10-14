//
//  ContentView.swift
//  GameMaker
//
//  Created by Douglas McNamara on 3/8/26.
//

import SwiftUI
import UniformTypeIdentifiers
import XGE
import JavaScriptCore

@MainActor
public func addUI(contentView:NSView) {
    var files:[URL] = []
    
    do {
        let items = try FileManager.default.contentsOfDirectory(at: AssetManager.rootURL!, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
        for item in items {
            var isDir = ObjCBool(false)
            
            if FileManager.default.fileExists(atPath: item.path, isDirectory: &isDir) {
                if item.pathExtension == "scene" && !isDir.boolValue {
                    files.append(item)
                }
            }
        }
        
        files = files.sorted { f1, f2 in
            f1.lastPathComponent < f2.lastPathComponent
        }
    } catch {
        Log.instance.put(error.localizedDescription)
    }
    
    let swiftUIView = ContentView(files:files)
    let hostingView = NSHostingView(rootView: swiftUIView)
    
    hostingView.frame = contentView.bounds
    hostingView.autoresizingMask = [.width, .height]
    contentView.addSubview(hostingView)
}

struct View3D : View {
    
    @Binding var selectedNode:Int
    @Binding var mouseMode:Int
    @Binding var snap:String
    @Binding var running:Bool
    @Binding var runURL:URL?
    @Binding var sceneURL:URL?
    @Binding var selectedNodeLabel:String
    @Binding var shouldLoadScene:Bool
    @Binding var shouldSaveScene:Bool
    @Binding var selectedURL:URL?
    @Binding var x2:Bool
    @Binding var value:String
    
    init(selectedNode: Binding<Int>,
         mouseMode: Binding<Int>,
         snap: Binding<String>,
         running: Binding<Bool>,
         runURL: Binding<URL?>,
         sceneURL: Binding<URL?>,
         selectedNodeLabel: Binding<String>,
         shouldLoadScene: Binding<Bool>,
         shouldSaveScene: Binding<Bool>,
         selectedURL: Binding<URL?>,
         x2: Binding<Bool>,
         value: Binding<String>
    ) {
        _selectedNode = selectedNode
        _mouseMode = mouseMode
        _snap = snap
        _running = running
        _runURL = runURL
        _sceneURL = sceneURL
        _selectedNodeLabel = selectedNodeLabel
        _shouldLoadScene = shouldLoadScene
        _shouldSaveScene = shouldSaveScene
        _selectedURL = selectedURL
        _x2 = x2
        _value = value
    }
    
    var body: some View {
        GameControl(selectedNode: $selectedNode,
                    mouseMode: $mouseMode,
                    snap: $snap,
                    running: $running,
                    runURL: $runURL,
                    sceneURL: $sceneURL,
                    selectedNodeLabel: $selectedNodeLabel,
                    shouldLoadScene: $shouldLoadScene,
                    shouldSaveScene: $shouldSaveScene,
                    selectedURL: $selectedURL,
                    x2: $x2,
                    value: $value
        )
        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
        .layoutPriority(1)
    }
}

struct AddComponentView : View {
    
    @Binding var isAddComponentShowing:Bool
    @Binding var selectedNode:Int
    @Binding var selectedNodeLabel:String
    @Binding var sceneURL:URL?
    
    init(isAddComponentShowing: Binding<Bool>, selectedNode: Binding<Int>, selectedNodeLabel: Binding<String>, sceneURL: Binding<URL?>) {
        _isAddComponentShowing = isAddComponentShowing
        _selectedNode = selectedNode
        _selectedNodeLabel = selectedNodeLabel
        _sceneURL = sceneURL
    }
    
    var body: some View {
        VStack {
            ScrollView {
                ForEach (Game.components, id: \.self) { name in
                    HStack {
                        Text(name)
                            .onTapGesture {
                                var add = sceneURL != nil
                                
                                if add {
                                    if let sceneURL = sceneURL {
                                        add = sceneURL.pathExtension == "scene"
                                    }
                                }
                                if add {
                                    addComponent(name: name)
                                    isAddComponentShowing = false
                                } else {
                                    Log.instance.put("scene not selected")
                                }
                            }
                        Spacer()
                    }
                }
            }
        }
        .frame(width:150, height:200)
        .padding()
    }
    
    func addComponent(name: String) {
        do {
            if let component = Game.factories[name] {
                let node = Node()
                
                node.position = GameView.instance!.scene.target
                node.position = GameView.instance!.scene.snap(node.position)
                
                try component.create(gameView: GameView.instance!, scene: GameView.instance!.scene, node: node)
                
                node.name = name
                node.gameComponent = component
                node.position = GameView.instance!.scene.target
                node.position = GameView.instance!.scene.snap(node.position)
                GameView.instance!.scene.root.addChild(node)
                
                selectedNode = GameView.instance!.scene.root.childCount - 1
                selectedNodeLabel = node.name
            }
        } catch {
            Log.instance.put(error.localizedDescription)
        }
    }
}

struct FileListView : View {
    
    @Binding var selectedURL:URL?
    @Binding var isAddComponentShowing:Bool
    @Binding var isAddSceneShowing:Bool
    @Binding var sceneName:String
    @Binding var isDeleteFileShowing:Bool
    @Binding var files:[URL]
    @Binding var running:Bool
    @Binding var sceneURL:URL?
    @Binding var selectedNode:Int
    @Binding var selectedNodeLabel:String
    @Binding var snap:String
    @Binding var shouldLoadScene:Bool
    @Binding var mouseMode:Int
    @Binding var runURL:URL?
    @Binding var value:String
    
    init(selectedURL: Binding<URL?>,
         isAddComponentShowing: Binding<Bool>,
         isAddSceneShowing: Binding<Bool>,
         sceneName: Binding<String>,
         isDeleteFileShowing: Binding<Bool>,
         files: Binding<[URL]>,
         running: Binding<Bool>,
         sceneURL: Binding<URL?>,
         selectedNode: Binding<Int>,
         selectedNodeLabel: Binding<String>,
         snap: Binding<String>,
         shouldLoadScene: Binding<Bool>,
         mouseMode: Binding<Int>,
         runURL: Binding<URL?>,
         value: Binding<String>
    ) {
        _selectedURL = selectedURL
        _isAddComponentShowing = isAddComponentShowing
        _isAddSceneShowing = isAddSceneShowing
        _sceneName = sceneName
        _isDeleteFileShowing = isDeleteFileShowing
        _files = files
        _running = running
        _sceneURL = sceneURL
        _selectedNode = selectedNode
        _selectedNodeLabel = selectedNodeLabel
        _snap = snap
        _shouldLoadScene = shouldLoadScene
        _mouseMode = mouseMode
        _runURL = runURL
        _value = value
    }
    
    var body: some View {
        List(files, id: \.self, selection: $selectedURL) { url in
            HStack {
                Text(url.lastPathComponent)
            }
            .listRowSeparator(.hidden)
        }
        .frame(width:400)
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
        .alert("Enter scene name", isPresented: $isAddSceneShowing) {
            TextField("Scene Name", text: $sceneName)
            HStack {
                Button("Cancel") {
                    isAddSceneShowing = false
                }
                Button("Add Scene") {
                    addScene()
                }
            }
        } message: {
            Text("Enter the name of the scene to add")
        }
        .alert("Delete selected file", isPresented: $isDeleteFileShowing) {
            Button("Yes") {
                deleteFile()
            }
            Button("No") {
                isDeleteFileShowing = false
            }
        } message: {
            Text("Do you want to delete the selected file? this can not be undone")
        }
        .contextMenu {
            Button("Add Scene") {
                isAddSceneShowing = true
            }
            .disabled(running)
            Button("Edit") {
                edit()
            }
            .disabled(((selectedURL == nil) ?  true : selectedURL!.pathExtension != "scene" && selectedURL!.pathExtension != "js" && selectedURL!.pathExtension != "txt") || running)
            Button("Delete") {
                isDeleteFileShowing = true
            }
            .disabled(selectedURL == nil || running)
            Button("Clear Selection") {
                selectedURL = nil
            }
            .disabled(running)
         }
        .disabled(running)
    }
    
    func addScene() {
        do {
            var name = sceneName
            
            name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if name.isEmpty {
                Log.instance.put("empty scene name")
                return
            } else {
                if (name as NSString).pathExtension != "scene" {
                    name = "\(name).scene"
                }
                let url = AssetManager.rootURL!.appending(path: name)
                
                if !FileManager.default.fileExists(atPath: url.path) {
                    var text = ""
                    
                    try text.write(to: url, atomically: true, encoding: .utf8)
                } else {
                    Log.instance.put("file already exists")
                }
            }
        } catch {
            Log.instance.put(error.localizedDescription)
        }
        isAddSceneShowing = false
        populateList()
    }
    
    func edit() {
        if let selectedURL = selectedURL {
            var scene = selectedURL.pathExtension == "scene"
            
            if scene {
                sceneURL = selectedURL
                selectedNode = -1
                value = ""
                selectedNodeLabel = ""
                shouldLoadScene = true
            } else {
                NSWorkspace.shared.open(selectedURL)
            }
        }
    }
    
    func deleteFile() {
        if let selectedURL = selectedURL {
            do {
                try FileManager.default.removeItem(at: selectedURL)
            } catch {
                Log.instance.put(error.localizedDescription)
            }
        } else {
            Log.instance.put("selected url not set")
        }
        isDeleteFileShowing = false
        populateList()
    }
    
    func populateList() {
        PopulateFileList(files: $files,
                         selectedNode: $selectedNode,
                         selectedNodeLabel: $selectedNodeLabel,
                         snap: $snap,
                         mouseMode: $mouseMode,
                         runURL: $runURL,
                         sceneURL: $sceneURL,
                         selectedURL: $selectedURL
        ).populateList()
    }
}

@MainActor
struct PopulateFileList {

    @Binding var files: [URL]
    @Binding var selectedNode:Int
    @Binding var selectedNodeLabel:String
    @Binding var snap:String
    @Binding var mouseMode:Int
    @Binding var runURL:URL?
    @Binding var sceneURL:URL?
    @Binding var selectedURL:URL?
    
    init(files: Binding<[URL]>,
         selectedNode: Binding<Int>,
         selectedNodeLabel: Binding<String>,
         snap: Binding<String>,
         mouseMode: Binding<Int>,
         runURL: Binding<URL?>,
         sceneURL: Binding<URL?>,
         selectedURL: Binding<URL?>
    ) {
        _files = files
        _selectedNode = selectedNode
        _selectedNodeLabel = selectedNodeLabel
        _snap = snap
        _mouseMode = mouseMode
        _runURL = runURL
        _sceneURL = sceneURL
        _selectedURL = selectedURL
    }
    
    func populateList() {
        do {
            let items = try FileManager.default.contentsOfDirectory(at: AssetManager.rootURL!, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            
            files.removeAll()
            for item in items {
                var isDir = ObjCBool(false)
                
                if FileManager.default.fileExists(atPath: item.path, isDirectory: &isDir) {
                    if item.pathExtension == "scene" && !isDir.boolValue {
                        files.append(item)
                    }
                }
            }
            
            files = files.sorted { f1, f2 in
                if f1.pathExtension == f2.pathExtension {
                    return f1.lastPathComponent < f2.lastPathComponent
                }
                return f1.pathExtension < f2.pathExtension
            }
        } catch {
            Log.instance.put(error.localizedDescription)
        }
        
        selectedNode = -1
        selectedNodeLabel = ""
        mouseMode = 0
        runURL = nil
        sceneURL = nil
        selectedURL = nil
        
        if let gameView = GameView.instance {
            gameView.newScene(inDesign: true)
        }
    }
}

struct ContentView: View {
    
    @State var files: [URL]
    @State var isAddComponentShowing = false
    @State var selectedURL: URL?
    @State var selectedNode:Int = -1
    @State var mouseMode = 0
    @State var snap = ""
    @State var running = false
    @State var runURL: URL?
    @State var sceneURL: URL?
    @State var shouldLoadScene = false
    @State var shouldSaveScene = false
    @State var selectedNodeLabel = ""
    @State var clearConsole = false
    @State var isAddSceneShowing = false
    @State var isDeleteItemShowing = false
    @State var sceneName = ""
    @State var isDeleteFileShowing = false
    @State var isShowingImportKFM = false
    @State var x2 = false
    @State var value = ""
    
    public init(files:[URL]) {
        self.files = files
    }

    var body: some View {
        VStack {
            HStack {
                Button("Run") {
                    let msg = "scene not selected in right hand list"
                    
                    if let selectedURL = selectedURL {
                        if selectedURL.pathExtension == "scene" {
                            sceneURL = nil
                            selectedNode = -1
                            selectedNodeLabel = ""
                            runURL = selectedURL
                            running = true
                        } else {
                            Log.instance.put(msg)
                        }
                    } else {
                        Log.instance.put(msg)
                    }
                }
                .disabled(running || !sceneSelected())
                Button("Import KFM") {
                    isShowingImportKFM = true
                }
                .fileImporter(isPresented: $isShowingImportKFM, allowedContentTypes: [ .directory ]) { result in
                    switch result {
                    case .success(let url):
                        if url.startAccessingSecurityScopedResource() {
                            do {
                                try importKFMesh(dir: url)
                            } catch {
                                Log.instance.put(error.localizedDescription)
                            }
                            url.stopAccessingSecurityScopedResource()
                        }
                        if let directory = AssetManager.rootURL {
                            populateList(url: directory)
                        }
                    case .failure(let error):
                        Log.instance.put(error.localizedDescription)
                    }
                }
                .disabled(running)
                Button("Save") {
                    shouldSaveScene = true
                }
                .disabled(running || sceneURL == nil)
                Button("Clear") {
                    clearConsole = true
                }
                Picker("", selection: $mouseMode) {
                    Text("ZRot").tag(0)
                    Text("Pan").tag(1)
                    Text("Sel").tag(2)
                    Text("Mov").tag(3)
                    Text("RX").tag(4)
                    Text("RY").tag(5)
                    Text("RZ").tag(6)
                }
                .disabled(running || sceneURL == nil)
                .pickerStyle(.segmented)
                Toggle("x2", isOn: $x2)
                
                Spacer()
            }
            .padding(EdgeInsets(top: 10, leading: 10, bottom: 5, trailing: 0))
            VSplitView {
                HStack {
                    View3D(selectedNode: $selectedNode,
                           mouseMode: $mouseMode,
                           snap: $snap,
                           running: $running,
                           runURL: $runURL,
                           sceneURL: $sceneURL,
                           selectedNodeLabel: $selectedNodeLabel,
                           shouldLoadScene: $shouldLoadScene,
                           shouldSaveScene: $shouldSaveScene,
                           selectedURL: $selectedURL,
                           x2: $x2,
                           value: $value
                    )
                    Divider()
                        .padding(0)
                    FileListView(selectedURL: $selectedURL,
                                 isAddComponentShowing: $isAddComponentShowing,
                                 isAddSceneShowing: $isAddSceneShowing,
                                 sceneName: $sceneName,
                                 isDeleteFileShowing: $isDeleteFileShowing,
                                 files: $files,
                                 running: $running,
                                 sceneURL: $sceneURL,
                                 selectedNode: $selectedNode,
                                 selectedNodeLabel: $selectedNodeLabel,
                                 snap: $snap,
                                 shouldLoadScene: $shouldLoadScene,
                                 mouseMode: $mouseMode,
                                 runURL: $runURL,
                                 value: $value
                    )
                }
                VStack {
                    HStack {
                        Button("+") {
                            isAddComponentShowing = true
                        }
                        .popover(isPresented: $isAddComponentShowing) {
                            AddComponentView(isAddComponentShowing: $isAddComponentShowing,
                                              selectedNode: $selectedNode,
                                              selectedNodeLabel: $selectedNodeLabel,
                                              sceneURL: $sceneURL
                            )
                        }
                        .disabled(running || sceneURL == nil)
                        Button("-") {
                            if selectedNode != -1 {
                                GameView.instance!.scene.root[selectedNode].detachFromParent()
                                selectedNode = -1
                            }
                            selectedNodeLabel = ""
                        }
                        .disabled(selectedNode == -1 || running || sceneURL == nil)
                        Button("ZP") {
                            if selectedNode != -1 {
                                GameView.instance!.scene.root[selectedNode].position = Vec3(0, 0,0 )
                            }
                        }
                        .disabled(selectedNode == -1 || running || sceneURL == nil)
                        Button("ZR") {
                            if selectedNode != -1 {
                                let node = GameView.instance!.scene.root[selectedNode]
                                
                                node.r = Vec3(1, 0, 0)
                                node.u = Vec3(0, 1, 0)
                                node.f = Vec3(0, 0, 1)
                            }
                        }
                        .disabled(selectedNode == -1 || running || sceneURL == nil)
                        Button("IC") {
                            let scene = GameView.instance!.scene
                            
                            scene.target = Vec3(0, 0, 0)
                            scene.eye = Vec3(200, 200, 200)
                            scene.up = Vec3(0, 1, 0)
                        }
                        .disabled(running || sceneURL == nil)
                        Button("RX45") {
                            if selectedNode != -1 {
                                GameView.instance!.scene.root[selectedNode].rotate(axis: 0, degrees: 45)
                            }
                        }
                        .disabled(selectedNode == -1 || running || sceneURL == nil)
                        Button("RY45") {
                            if selectedNode != -1 {
                                GameView.instance!.scene.root[selectedNode].rotate(axis: 1, degrees: 45)
                            }
                        }
                        .disabled(selectedNode == -1 || running || sceneURL == nil)
                        Button("RZ45") {
                            if selectedNode != -1 {
                                GameView.instance!.scene.root[selectedNode].rotate(axis: 2, degrees: 45)
                            }
                        }
                        .disabled(selectedNode == -1 || running || sceneURL == nil)
                        TextField("Snap", text:  $snap)
                            .frame(width:75)
                            .disabled(running || sceneURL == nil)
                        TextField("value", text: $value)
                            .frame(width: 75)
                            .disabled(running || sceneURL == nil)
                        Text(selectedNodeLabel)
                        Spacer()
                    }
                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 5, trailing: 0))
                    ConsoleView(clear: $clearConsole)
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                }
            }
        }
    }
    
    func sceneSelected() -> Bool {
        if let selectedURL = selectedURL {
            return selectedURL.pathExtension == "scene"
        }
        return false
    }
    
    func populateList(url:URL) {
        PopulateFileList(files: $files,
                         selectedNode: $selectedNode,
                         selectedNodeLabel: $selectedNodeLabel,
                         snap: $snap,
                         mouseMode: $mouseMode,
                         runURL: $runURL,
                         sceneURL: $sceneURL,
                         selectedURL: $selectedURL
        ).populateList()
    }
}

