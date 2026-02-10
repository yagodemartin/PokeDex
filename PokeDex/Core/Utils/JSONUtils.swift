import Foundation

class JSONUtils {
    // Método para cargar un archivo JSON desde el bundle adecuado
    static func loadJSONFromFile<T: Decodable>(filename: String, type: T.Type, bundle: Bundle) -> T? {
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            print("No se pudo encontrar el archivo \(filename).json en el bundle")
            return nil
        }

        do {
            let data = try Data(contentsOf: url) // Obtener los datos del archivo
            let decoder = JSONDecoder()
            let object = try decoder.decode(T.self, from: data) // Decodificar a la clase deseada
            return object
        } catch {
            print("Error al leer o decodificar el archivo \(filename).json: \(error)")
            return nil
        }
    }
}
