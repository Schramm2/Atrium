import React, { useState, useEffect } from "react";
import { invoke } from '@tauri-apps/api/core';
import { getVersion } from '@tauri-apps/api/app';
import Image from 'next/image';
import AnalyticsConsentSwitch from "./AnalyticsConsentSwitch";
import { UpdateDialog } from "./UpdateDialog";
import { updateService, UpdateInfo } from '@/services/updateService';
import { Button } from './ui/button';
import { Loader2, CheckCircle2 } from 'lucide-react';
import { toast } from 'sonner';


export function About() {
    const [currentVersion, setCurrentVersion] = useState<string>('0.4.0');
    const [updateInfo, setUpdateInfo] = useState<UpdateInfo | null>(null);
    const [isChecking, setIsChecking] = useState(false);
    const [showUpdateDialog, setShowUpdateDialog] = useState(false);

    useEffect(() => {
        // Get current version on mount
        getVersion().then(setCurrentVersion).catch(console.error);
    }, []);

    const handleContactClick = async () => {
        try {
            await invoke('open_external_url', { url: 'https://ubundi.co.za' });
        } catch (error) {
            console.error('Failed to open link:', error);
        }
    };

    const handleCheckForUpdates = async () => {
        setIsChecking(true);
        try {
            const info = await updateService.checkForUpdates(true);
            setUpdateInfo(info);
            if (info.available) {
                setShowUpdateDialog(true);
            } else {
                toast.success('You are running the latest version');
            }
        } catch (error: any) {
            console.error('Failed to check for updates:', error);
            toast.error('Failed to check for updates: ' + (error.message || 'Unknown error'));
        } finally {
            setIsChecking(false);
        }
    };

    return (
        <div className="ubundi-about p-6 space-y-6 h-[80vh] overflow-y-auto">
            {/* Compact Header */}
            <div className="text-center">
                <div className="mb-3">
                    <Image
                        src="/ubundi-mark.png"
                        alt="Ubundi"
                        width={72}
                        height={72}
                        className="mx-auto rounded-2xl"
                    />
                </div>
                {/* <h1 className="text-xl font-bold text-gray-900">Meetily</h1> */}
                <p className="text-sm text-[#5F6368] mt-2">
                    Ubundi Meet · v{currentVersion}
                </p>
                <p className="text-sm text-[#5F6368] mt-2">
                    Real-time notes and summaries that keep your context close to the work.
                </p>
                <div className="mt-3">
                    <Button
                        onClick={handleCheckForUpdates}
                        disabled={isChecking}
                        variant="outline"
                        size="sm"
                        className="text-xs border-[#DADCE0] text-[#2F3498] hover:bg-[#F2F5FC]"
                    >
                        {isChecking ? (
                            <>
                                <Loader2 className="h-3 w-3 mr-2 animate-spin" />
                                Checking...
                            </>
                        ) : (
                            <>
                                <CheckCircle2 className="h-3 w-3 mr-2" />
                                Check for Updates
                            </>
                        )}
                    </Button>
                    {updateInfo?.available && (
                        <div className="mt-2 text-xs text-blue-600">
                            Update available: v{updateInfo.version}
                        </div>
                    )}
                </div>
            </div>

            {/* Features Grid - Compact */}
            <div className="space-y-3">
                <h2 className="text-base font-semibold text-[#171B48]">What makes Ubundi Meet different</h2>
                <div className="grid grid-cols-2 gap-2">
                    <div className="bg-[#F5F5F5] border border-[#DADCE0] rounded-lg p-4 hover:bg-[#F2F5FC] transition-colors">
                        <h3 className="font-semibold text-sm text-[#171B48] mb-1">Private by default</h3>
                        <p className="text-xs text-[#5F6368] leading-relaxed">Your recordings, transcripts, and AI workflow can stay on your machine.</p>
                    </div>
                    <div className="bg-[#F5F5F5] border border-[#DADCE0] rounded-lg p-4 hover:bg-[#F2F5FC] transition-colors">
                        <h3 className="font-semibold text-sm text-[#171B48] mb-1">Your choice of model</h3>
                        <p className="text-xs text-[#5F6368] leading-relaxed">Use a local model or connect a provider when the work calls for it.</p>
                    </div>
                    <div className="bg-[#F5F5F5] border border-[#DADCE0] rounded-lg p-4 hover:bg-[#F2F5FC] transition-colors">
                        <h3 className="font-semibold text-sm text-[#171B48] mb-1">Cost-aware</h3>
                        <p className="text-xs text-[#5F6368] leading-relaxed">Run locally when you want to avoid pay-per-minute processing costs.</p>
                    </div>
                    <div className="bg-[#F5F5F5] border border-[#DADCE0] rounded-lg p-4 hover:bg-[#F2F5FC] transition-colors">
                        <h3 className="font-semibold text-sm text-[#171B48] mb-1">Built for real work</h3>
                        <p className="text-xs text-[#5F6368] leading-relaxed">Capture conversations across Meet, Zoom, Teams, or in the room.</p>
                    </div>
                </div>
            </div>

            {/* Coming Soon - Compact */}
            <div className="bg-[#1B1F44] rounded-lg p-4">
                <p className="text-sm text-white/80">
                    <span className="font-semibold text-[#C183E6]">On the horizon:</span> on-device agents for follow-ups, action tracking, and more.
                </p>
            </div>

            {/* CTA Section - Compact */}
            <div className="text-center space-y-2">
                <h3 className="text-base font-semibold text-[#171B48]">Built for the Ubundi way of working</h3>
                <p className="text-sm text-[#5F6368]">
                    Keep conversations clear, useful, and connected to the work that follows.
                </p>
                <button
                    onClick={handleContactClick}
                    className="inline-flex items-center px-4 py-2 bg-[#2F3498] hover:bg-[#1B1F44] text-white text-sm font-semibold rounded-lg transition-colors duration-200"
                >
                    Explore Ubundi
                </button>
            </div>

            {/* Footer - Compact */}
            <div className="pt-2 border-t border-[#DADCE0] text-center">
                <p className="text-xs text-[#697988]">
                    Built for Ubundi
                </p>
            </div>
            <AnalyticsConsentSwitch />

            {/* Update Dialog */}
            <UpdateDialog
                open={showUpdateDialog}
                onOpenChange={setShowUpdateDialog}
                updateInfo={updateInfo}
            />
        </div>

    )
}
