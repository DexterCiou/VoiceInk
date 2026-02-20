// DictionaryView.swift
// VoiceInk — 自訂字典頁面

import SwiftUI
import SwiftData

/// 自訂字典頁面，讓使用者管理特殊詞彙以提升 LLM 辨識準確度
struct DictionaryView: View {
    // MARK: - 環境

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DictionaryWord.createdAt, order: .reverse) private var words: [DictionaryWord]

    // MARK: - 狀態

    @State private var newWord: String = ""
    @State private var searchText: String = ""
    @State private var isAddingWord = false

    /// 根據搜尋文字篩選詞彙
    private var filteredWords: [DictionaryWord] {
        if searchText.isEmpty {
            return words
        }
        return words.filter { $0.word.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 標題列
                HStack {
                    Text("字典")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    Button {
                        isAddingWord = true
                    } label: {
                        Text("新增單字")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                }

                // 搜尋列
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("搜尋字典...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // 說明文字
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("加入特殊詞彙，AI 潤飾時會優先使用這些字詞，提升辨識準確度。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("共 \(words.count) 個詞彙")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // 詞彙列表（三欄格狀排列）
                if filteredWords.isEmpty {
                    emptyStateView
                } else {
                    wordGridView
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $isAddingWord) {
            addWordSheet
        }
    }

    // MARK: - 元件

    /// 空狀態
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "character.book.closed.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "尚未新增任何詞彙" : "找不到符合的詞彙")
                .font(.headline)
                .foregroundStyle(.secondary)
            if searchText.isEmpty {
                Text("點擊「新增單字」來加入特殊用語")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    /// 詞彙格狀排列
    private var wordGridView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(filteredWords) { word in
                wordCard(word)
            }
        }
    }

    /// 單個詞彙卡片
    private func wordCard(_ word: DictionaryWord) -> some View {
        HStack {
            Image(systemName: "textformat")
                .foregroundStyle(.blue)
                .font(.caption)
            Text(word.word)
                .lineLimit(1)
            Spacer()
            Button {
                deleteWord(word)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    /// 新增詞彙彈出視窗
    private var addWordSheet: some View {
        VStack(spacing: 16) {
            Text("新增單字")
                .font(.headline)

            TextField("輸入詞彙（例如：Claude Code）", text: $newWord)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    addWord()
                }

            Text("輸入不常見的專有名詞、品牌名、人名等，AI 潤飾時會優先辨識。")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button("取消") {
                    newWord = ""
                    isAddingWord = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("新增") {
                    addWord()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newWord.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 380)
    }

    // MARK: - 操作

    /// 新增詞彙到字典
    private func addWord() {
        let trimmed = newWord.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // 檢查是否已存在
        if words.contains(where: { $0.word == trimmed }) {
            newWord = ""
            isAddingWord = false
            return
        }

        let word = DictionaryWord(word: trimmed)
        modelContext.insert(word)
        try? modelContext.save()
        newWord = ""
        isAddingWord = false
    }

    /// 刪除詞彙
    private func deleteWord(_ word: DictionaryWord) {
        modelContext.delete(word)
        try? modelContext.save()
    }
}
