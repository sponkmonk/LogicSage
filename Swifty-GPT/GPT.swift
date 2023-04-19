//
//  GPT.swift
//  Swifty-GPT
//
//  Created by Chris Dillard on 4/15/23.
//

import Foundation

let gptModel = "gpt-3.5-turbo" // Can someone out there hook me up with "gpt-4" ;)

// Function to send a prompt to GPT via the OpenAI API
func sendPromptToGPT(prompt: String, currentRetry: Int, isFix: Bool = false, manualPrompt: Bool = false,  completion: @escaping (String, Bool) -> Void) {

    let url = URL(string: apiEndpoint)!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    // Set the required headers
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer \(OPEN_AI_KEY)", forHTTPHeaderField: "Authorization")

    // Prepare the request payload
    let requestBody: [String: Any] = [
        "model": "\(gptModel)",
        "messages": [
            [
                "role": "user",
                "content": manualPrompt ? manualPromptString : prompt,
            ]
        ]
    ]
    do {
        // Convert the payload to JSON data
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])

        request.httpBody = jsonData


        if currentRetry == 0 {
            print("👨: \(prompt)")
        }
        if isFix {
            print("💚: Try fix prompt: \(currentRetry) / \(retryLimit) \\n \(prompt)")

        }
        else if manualPrompt {
            print("👨: \(manualPrompt)")

        }
        // Look into a better way to handle prompts..... 3
        else {
            print("prompt=\(prompt)")
            print("👨: Retry same prompt: \(currentRetry) / \(retryLimit)")
        }

        startRandomSpinner()

        textToSpeech(text: "Exec prompt length \(prompt.count)", overrideWpm: "242")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in


            stopRandomSpinner()

            if let error = error {
                print("Error occurred: \(error.localizedDescription)")
                completion("Failed networking w/ error = \(error)", false)
                return
            }

            guard let data  else {
                completion("Failed networking w/ error = \(String(describing: error))", false)
                return print("failed to laod data")
            }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(content, true)
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
                completion("Failed parsing JSON w/ error = \(error)",false)
                completion("", false)

            }
        }
        print("🐑🧠🐑🧠🐑🧠🐑🧠🐑🧠 THINKING... 🧠🐑🧠🐑🧠🐑🧠🐑🧠🐑🧠🐑")
        task.resume()
    }
    catch {
        return completion("Failed parsing w/ error = \(error)", false)
    }
}

