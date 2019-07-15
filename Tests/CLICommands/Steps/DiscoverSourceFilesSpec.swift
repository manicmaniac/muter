import Quick
import Nimble
import Foundation
@testable import muterCore

class DiscoverSourceFilesSpec: QuickSpec {
    override func spec() {
        describe("the DiscoverSourceFiles step") {
            var discoverSourceFiles: DiscoverSourceFiles!
            var state: RunCommandState!
            
            beforeEach {
                state = RunCommandState()
                state.projectDirectoryURL = URL(fileURLWithPath: self.fixturesDirectory)
                
                discoverSourceFiles = DiscoverSourceFiles()
            }
            
            context("when it discovers Swift files contained in a project directory") {
                var result: Result<[RunCommandState.Change], MuterError>! // keep this as locally defined as possible to avoid test pollution
                let path = "\(self.fixturesDirectory)/FilesToDiscover"
                
                beforeEach {
                    state.tempDirectoryURL = URL(fileURLWithPath: path, isDirectory: true)
                    result = discoverSourceFiles.run(with: state)
                }
                
                it("returns the discovered Swift files, sorted alphabetically") {
                    guard case .success(let stateChanges) = result! else {
                        fail("expected success but got \(String(describing: result!))")
                        return
                    }
                    
                    expect(stateChanges) == [.sourceFileCandidatesDiscovered([
                        "\(path)/Directory1/file3.swift",
                        "\(path)/Directory2/Directory3/file6.swift",
                        "\(path)/ExampleApp/ExampleAppCode.swift",
                        "\(path)/file1.swift",
                        "\(path)/file2.swift",
                        ])]
                }
            
                context("when there is a user provided exclude list") {
                    var result: Result<[RunCommandState.Change], MuterError>! // keep this as locally defined as possible to avoid test pollution

                    it("excludes Swift files which match against the exclude list") {
                        let path = "\(self.fixturesDirectory)/FilesToDiscover"
                        state.muterConfiguration = MuterConfiguration(executable: "", arguments: [], excludeList: ["ExampleApp"])
                        state.tempDirectoryURL = URL(fileURLWithPath: path, isDirectory: true)
                        
                        result = discoverSourceFiles.run(with: state)
                    }
                    
                    it("returns the discovered source files, sorted alphabetically, with the exclude list applied") {
                        guard case .success(let stateChanges) = result! else {
                            fail("expected success but got \(String(describing: result!))")
                            return
                        }
                        
                        expect(stateChanges) == [.sourceFileCandidatesDiscovered([
                            "\(path)/Directory1/file3.swift",
                            "\(path)/Directory2/Directory3/file6.swift",
                            "\(path)/file1.swift",
                            "\(path)/file2.swift",
                            ])]
                    }
                }
            }
            
            context("when it doesn't discover any Swift files in a project directory") {
                var result: Result<[RunCommandState.Change], MuterError>! // keep this as locally defined as possible to avoid test pollution
                
                context("because a project directory contains 0 Swift files") {
                    beforeEach {
                        state.tempDirectoryURL = URL(fileURLWithPath: "\(self.fixturesDirectory)/FilesToDiscover/Directory4",
                                                     isDirectory: true)
                        result = discoverSourceFiles.run(with: state)
                    }
                    
                    it("cascades a failure") {
                        guard case .failure(.noSourceFilesDiscovered) = result! else {
                            fail("expected noSourceFilesDiscovered but got \(String(describing: result!))")
                            return
                            
                        }
                    }
                }
                
                context("because the directory doesn't exist") {
                    beforeEach {
                        let path = "I don't exist"
                        
                        state.tempDirectoryURL = URL(fileURLWithPath: path, isDirectory: true)
                        result = discoverSourceFiles.run(with: state)
                    }
                    
                    it("cascades a failure") {
                        guard case .failure(.noSourceFilesDiscovered) = result! else {
                            fail("expected noSourceFilesDiscovered but got \(String(describing: result!))")
                            return
                            
                        }
                    }
                }
            }
        }
    }
}
