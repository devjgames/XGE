//
//  ConsoleView.swift
//  XGE
//
//  Created by Douglas McNamara on 2/15/26.
//

import SwiftUI
import XGE

@MainActor
class ConsoleTextView : NSTextView {
    
    public required init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 1, height: 1))
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    public override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override func didChangeText() {
        super.didChangeText()
        invalidateIntrinsicContentSize()
    }
    
    public override var intrinsicContentSize: NSSize {
        if let layoutManager = self.layoutManager, let textContainer = self.textContainer {
            layoutManager.ensureLayout(for: textContainer)
            let usedRect = layoutManager.usedRect(for: textContainer)
            let contentHeight = usedRect.height + self.textContainerInset.height * 2
            return NSSize(width: NSView.noIntrinsicMetric, height: contentHeight)
        }
        return super.intrinsicContentSize
    }
}

@MainActor
struct ConsoleView : NSViewRepresentable {
    
    @Binding public var clear:Bool
    
    public init(clear:Binding<Bool>) {
        _clear = clear
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    public func makeNSView(context: Context) -> some NSView {
        let scrollView = NSTextView.scrollableTextView()
        let textView:ConsoleTextView = ConsoleTextView()
        
        scrollView.documentView = textView
        
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isRichText = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = NSColor.textColor
        
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        textView.allowsUndo = true
        textView.autoresizingMask = .width
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.minSize = NSSize(width: 0, height: scrollView.contentSize.height)
        textView.isHorizontallyResizable = false
        textView.textContainer!.widthTracksTextView = true
        textView.textContainer!.heightTracksTextView = false
        textView.isVerticallyResizable = true
        
        textView.isEditable = false
        textView.isSelectable = false
        
        context.coordinator.textView = textView
        
        return scrollView
    }
    
    public func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSViewType, context: Context) -> CGSize? {
        nil
    }
    
    public func updateNSView(_ nsView: NSViewType, context: Context) {
        if clear {
            context.coordinator.clear()
            DispatchQueue.main.async {
                clear = false
            }
        }
    }
    
    public class Coordinator : Log {
        
        var textView:ConsoleTextView?
        
        private var _parent:ConsoleView
        
        public init(parent:ConsoleView) {
            _parent = parent
            
            super.init()
        }
        
        public override func put(_ value: Any) {
            textView!.textColor = NSColor.textColor
            textView!.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            textView!.string += "\(value)\n"
            textView!.scrollToEndOfDocument(textView!)
        }
        
        public func clear() {
            textView!.string = ""
        }
    }
}

