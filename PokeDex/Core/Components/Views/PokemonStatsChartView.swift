//
//  PokemonStatsChartView.swift
//  PokeDex
//
//  Created by yamartin on 18/2/25.
//

import SwiftUI
import Charts


struct PokemonStatsChartView: View {


    let stats: PokemonStats
    let markColors: [LinearGradient] = [
        LinearGradient(colors: [Color.Stats.hp, Color.Stats.hp.adjust(brightness: -0.30)], startPoint: .leading, endPoint: .trailing),
        LinearGradient(colors: [Color.Stats.attack, Color.Stats.attack.adjust(brightness: -0.30)], startPoint: .leading, endPoint: .trailing),
        LinearGradient(colors: [Color.Stats.defense, Color.Stats.defense.adjust(brightness: -0.30)], startPoint: .leading, endPoint: .trailing),
        LinearGradient(colors: [Color.Stats.specialAttack, Color.Stats.specialAttack.adjust(brightness: -0.30)], startPoint: .leading, endPoint: .trailing),
        LinearGradient(colors: [Color.Stats.specialDef, Color.Stats.specialDef.adjust(brightness: -0.30)], startPoint: .leading, endPoint: .trailing),
        LinearGradient(colors: [Color.Stats.speed, Color.Stats.speed.adjust(brightness: -0.30)], startPoint: .leading, endPoint: .trailing)
    ]

    @State var data: [ChartData] = []

    var body: some View {

        VStack{

            Text("Stats")
                .font(.title)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)


            Chart(data) { dataPoint in
                BarMark(x: .value("Stat", dataPoint.count),
                        y: .value("Type", dataPoint.type))
                .foregroundStyle(by: .value("Type", dataPoint.type))
                .annotation(position: .trailing) {
                    //                            Text(String(dataPoint.count))
                    //                                .foregroundColor(.gray)
                    AnnotationView(workout: dataPoint, data: data)
                }
            }
            .chartLegend(.hidden)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                }
            }
            .chartForegroundStyleScale(domain: data.compactMap({ data in
                data.id
            }), range: markColors)
            .aspectRatio(1, contentMode: .fit)
            .padding(.horizontal)
            .onAppear {
                self.data = [ChartData(type: "Hp", count: stats.hp),
                             ChartData(type: "Attack", count: stats.attack),
                             ChartData(type: "Defense", count: stats.defense),
                             ChartData(type: "Sp. Attack", count: stats.specialAttack),
                             ChartData(type: "Sp. Def.", count: stats.specialDefense),
                             ChartData(type: "Speed", count: stats.speed)]

            }
        }
    }
}

    struct AnnotationView: View {
        let workout: ChartData
        var data: [ChartData]

        var body: some View {
            let idx = data.firstIndex(where: {$0.id == workout.id}) ?? 0
            return HStack(spacing: 10) {
                Text(String(workout.count))
                    .foregroundColor(.gray)
                getImagenFromIndex(index: idx)
                    .resizable()
                    .frame(width: 15, height: 15)
                    .foregroundColor(getColorFromIndex(index: idx))
            }
            .font(.caption)
            .foregroundStyle(Color.Stats.attack)
            .frame(minWidth: 50)
            .padding(.leading , 0 )
        }
    }

    func getImagenFromIndex(index: Int) -> Image {

        switch index {

        case 0:
            return Image("hp")
        case 1:
            return Image("espada")
        case 2:
            return Image("shield")
        case 3:
            return Image("swords")
        case 4:
            return Image("starShield")
        case 5:
            return Image("speed")

        default:
            return Image("hp")

        }
    }


func getColorFromIndex(index: Int) -> Color {

    switch index {

    case 0:
        return Color.Stats.hp
    case 1:
        return Color.Stats.attack
    case 2:
        return Color.Stats.defense
    case 3:
        return Color.Stats.specialAttack
    case 4:
        return Color.Stats.specialDef
    case 5:
        return Color.Stats.speed

    default:
        return Color.Stats.speed
    }
}



struct ChartData: Identifiable, Equatable {
    let type: String
    let count: Int

    var id: String { return type }
}



