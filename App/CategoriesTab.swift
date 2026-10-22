import ChillyCore
import SwiftUI

struct CategoriesTab: View {
    @Environment(TimerEngine.self) private var engine
    @State private var editing: TimerCategory?

    var body: some View {
        VStack(alignment: .leading) {
            List {
                ForEach(engine.state.categories) { c in
                    HStack {
                        Image(systemName: c.symbol).foregroundStyle(Color(hex: c.colorHex)).frame(width: 22)
                        VStack(alignment: .leading) {
                            Text(c.name)
                            Text(c.kind.label + (c.builtIn ? " · built-in" : ""))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Edit") { editing = c }
                        if engine.canDelete(c) {
                            Button(role: .destructive) { engine.deleteCategory(c.id) } label: { Image(systemName: "trash") }
                                .buttonStyle(.borderless)
                        }
                    }
                }
            }
            Button {
                editing = TimerCategory(name: "My category", symbol: "star", colorHex: "#8E8E93", kind: .repeating,
                                        interval: 30 * 60, breakDuration: 30, message: "Time for a break.")
            } label: { Label("New category", systemImage: "plus") }
        }
        .padding()
        .sheet(item: $editing) { c in
            CategoryForm(category: c) { engine.saveCategory($0) }
        }
    }
}

private struct CategoryForm: View {
    @Environment(\.dismiss) private var dismiss
    @State var category: TimerCategory
    let onSave: (TimerCategory) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Form {
                TextField("Name", text: $category.name)
                LabeledContent("Icon (SF Symbol name)") {
                    HStack {
                        TextField("", text: $category.symbol).frame(width: 160)
                        Image(systemName: category.symbol).foregroundStyle(Color(hex: category.colorHex))
                    }
                }
                ColorPicker("Color", selection: Binding(get: { Color(hex: category.colorHex) },
                                                        set: { category.colorHex = $0.hexString }),
                            supportsOpacity: false)
                Section("Defaults for new timers") {
                    Picker("Type", selection: $category.kind) {
                        ForEach(TimerKind.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    LabeledContent("Interval (minutes)") {
                        TextField("", value: Binding(get: { category.interval / 60 }, set: { category.interval = $0 * 60 }),
                                  format: .number).frame(width: 70)
                    }
                    LabeledContent("Break (seconds)") {
                        TextField("", value: $category.breakDuration, format: .number).frame(width: 70)
                    }
                    TextField("Message", text: $category.message, axis: .vertical)
                }
            }
            .formStyle(.grouped)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Save") { onSave(category); dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(category.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .frame(width: 440, height: 460)
    }
}
