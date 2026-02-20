// SoundPlayer.swift
// VoiceInk — 提示音播放工具

import AppKit

/// 提示音播放工具，使用系統內建音效
enum SoundPlayer {
    /// 音效類型
    enum SoundType {
        /// 開始錄音提示音
        case startRecording
        /// 結束錄音提示音
        case stopRecording
        /// 轉錄完成提示音
        case transcriptionComplete
        /// 錯誤提示音
        case error
    }

    /// 播放指定類型的提示音
    /// - Parameter type: 音效類型
    static func play(_ type: SoundType) {
        // 若使用者關閉了提示音，則不播放
        guard UserDefaults.standard.bool(forKey: "enableSoundEffects") else { return }

        let soundName: NSSound.Name
        switch type {
        case .startRecording:
            soundName = "Tink"
        case .stopRecording:
            soundName = "Pop"
        case .transcriptionComplete:
            soundName = "Glass"
        case .error:
            soundName = "Basso"
        }

        NSSound(named: soundName)?.play()
    }
}
