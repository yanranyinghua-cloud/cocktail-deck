import SwiftUI

// 搜索＋筛选条：搜索中英文名、材料名；基酒多选改为单选芯片（一阶段简化，
// 多选叠加是二阶段）；核验状态三档筛选；选择会记住——持久化是二阶段任务。
struct SearchFilterBar: View {
    @Bindable var viewModel: DeckViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜酒名、材料", text: $viewModel.searchText)
                    .textInputAutocapitalization(.never)
                if viewModel.hasActiveFilters {
                    Button("清除") { viewModel.clearFilters() }
                        .font(.subheadline)
                }
            }
            .padding(10)
            .background(Color.secondary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "全部基酒", selected: viewModel.selectedBaseSpirit == nil) {
                        viewModel.selectedBaseSpirit = nil
                    }
                    ForEach(viewModel.allBaseSpirits, id: \.self) { spirit in
                        FilterChip(title: spirit, selected: viewModel.selectedBaseSpirit == spirit) {
                            viewModel.selectedBaseSpirit = (viewModel.selectedBaseSpirit == spirit) ? nil : spirit
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                Text("核验：").font(.subheadline).foregroundStyle(.secondary)
                FilterChip(title: "全部", selected: viewModel.selectedLabel == nil) {
                    viewModel.selectedLabel = nil
                }
                ForEach([VerificationLabel.verified, .pending, .incomplete, .custom], id: \.self) { label in
                    FilterChip(title: label.rawValue, selected: viewModel.selectedLabel == label) {
                        viewModel.selectedLabel = (viewModel.selectedLabel == label) ? nil : label
                    }
                }
                Spacer()
                Text("共 \(viewModel.filteredDrinks.count) 款")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

private struct FilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected ? Color.accentColor : Color.secondary.opacity(0.12))
                .foregroundStyle(selected ? Color.white : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
