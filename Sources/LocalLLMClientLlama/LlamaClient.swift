import Foundation
import LocalLLMClient

/// A client for interacting with the Llama models.
///
/// This class provides methods for generating text streams from various inputs,
/// and handles the communication with the underlying Llama model.
public final class LlamaClient: LLMClient {
    private let context: Context
    private let multimodal: MultimodalContext?
    private let messageDecoder: any LlamaChatMessageDecoder

    /// Initializes a new Llama client.
    ///
    /// - Parameters:
    ///   - url: The URL of the Llama model file.
    ///   - mmprojURL: The URL of the multimodal projector file (optional).
    ///   - parameter: The parameters for the Llama model.
    ///   - messageDecoder: The message decoder to use for chat messages (optional).
    /// - Throws: An error if the client fails to initialize.
    public init(
        url: URL,
        mmprojURL: URL?,
        parameter: Parameter,
        messageDecoder: (any LlamaChatMessageDecoder)?
    ) throws {
        context = try Context(url: url, parameter: parameter)
        if let mmprojURL {
            multimodal = try MultimodalContext(url: mmprojURL, context: context, parameter: parameter)
        } else {
            multimodal = nil
        }
        self.messageDecoder = messageDecoder ?? LlamaAutoMessageDecoder(chatTemplate: context.model.chatTemplate)
    }

    /// Generates a text stream from the given input.
    ///
    /// - Parameter input: The input to generate text from.
    /// - Returns: A generator that produces text as it's generated by the model.
    /// - Throws: An `LLMError.failedToDecode` error if the input cannot be decoded.
    public func textStream(from input: LLMInput) throws -> Generator {
        do {
            switch input.value {
            case .plain(let text):
                context.clear()
                try context.decode(text: text)
            case .chatTemplate(let messages):
                try messageDecoder.decode(messages, context: context, multimodal: multimodal)
            case .chat(let messages):
                let value = messageDecoder.templateValue(from: messages)
                try messageDecoder.decode(value, context: context, multimodal: multimodal)
            }
        } catch {
            throw LLMError.failedToDecode(reason: error.localizedDescription)
        }

        return Generator(context: context)
    }
}

public extension LocalLLMClient {
    /// Creates a new Llama client.
    ///
    /// This is a factory method for creating `LlamaClient` instances.
    ///
    /// - Parameters:
    ///   - url: The URL of the Llama model file.
    ///   - mmprojURL: The URL of the multimodal projector file (optional).
    ///   - parameter: The parameters for the Llama model. Defaults to `.default`.
    ///   - messageDecoder: The message decoder to use for chat messages (optional).
    ///   - verbose: A Boolean value indicating whether to enable verbose logging. Defaults to `false`.
    /// - Returns: A new `LlamaClient` instance.
    /// - Throws: An error if the client fails to initialize.
    static func llama(
        url: URL,
        mmprojURL: URL? = nil,
        parameter: LlamaClient.Parameter = .default,
        messageDecoder: (any LlamaChatMessageDecoder)? = nil
    ) async throws -> LlamaClient {
        setLlamaVerbose(parameter.options.verbose)
        return try LlamaClient(
            url: url,
            mmprojURL: mmprojURL,
            parameter: parameter,
            messageDecoder: messageDecoder
        )
    }
}

#if DEBUG
extension LlamaClient {
    var _context: Context {
        context
    }

    var _multimodal: MultimodalContext? {
        multimodal
    }
}
#endif
