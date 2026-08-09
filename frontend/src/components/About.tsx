import React, { useState, useEffect } from "react";
import { invoke } from '@tauri-apps/api/core';
import { getVersion } from '@tauri-apps/api/app';
import { BrandMark } from './BrandIdentity';
import { UpdateDialog } from "./UpdateDialog";
import { updateService, UpdateInfo } from '@/services/updateService';
import { Button } from './ui/button';
import { Loader2, CheckCircle2 } from 'lucide-react';
import { toast } from 'sonner';


export function About() {
    const [currentVersion, setCurrentVersion] = useState<string>('0.5.0');
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
                    <BrandMark size={72} className="mx-auto" />
                </div>
                {/* <h1 className="text-xl font-bold text-gray-900">Ubundi Meet</h1> */}
                <p className="brand-about-muted text-sm mt-2">
                    Ubundi Meet · v{currentVersion}
                </p>
                <p className="brand-about-muted text-sm mt-2">
                    Real-time notes and summaries that keep your context close to the work.
                </p>
                <div className="mt-3">
                    <Button
                        onClick={handleCheckForUpdates}
                        disabled={isChecking}
                        variant="outline"
                        size="sm"
                        className="brand-about-check text-xs"
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
                <h2 className="brand-about-heading text-base font-semibold">What makes Ubundi Meet different</h2>
                <div className="grid grid-cols-2 gap-2">
                    <div className="brand-about-card border rounded-lg p-4 transition-colors">
                        <h3 className="brand-about-heading font-semibold text-sm mb-1">Private by default</h3>
                        <p className="brand-about-muted text-xs leading-relaxed">Your recordings, transcripts, and AI workflow can stay on your machine.</p>
                    </div>
                    <div className="brand-about-card border rounded-lg p-4 transition-colors">
                        <h3 className="brand-about-heading font-semibold text-sm mb-1">Your choice of model</h3>
                        <p className="brand-about-muted text-xs leading-relaxed">Use a local model or connect a provider when the work calls for it.</p>
                    </div>
                    <div className="brand-about-card border rounded-lg p-4 transition-colors">
                        <h3 className="brand-about-heading font-semibold text-sm mb-1">Cost-aware</h3>
                        <p className="brand-about-muted text-xs leading-relaxed">Run locally when you want to avoid pay-per-minute processing costs.</p>
                    </div>
                    <div className="brand-about-card border rounded-lg p-4 transition-colors">
                        <h3 className="brand-about-heading font-semibold text-sm mb-1">Built for real work</h3>
                        <p className="brand-about-muted text-xs leading-relaxed">Capture conversations across Meet, Zoom, Teams, or in the room.</p>
                    </div>
                </div>
            </div>

            {/* CTA Section - Compact */}
            <div className="text-center space-y-2">
                <h3 className="brand-about-heading text-base font-semibold">Built for the Ubundi way of working</h3>
                <p className="brand-about-muted text-sm">
                    Keep conversations clear, useful, and connected to the work that follows.
                </p>
                <button
                    onClick={handleContactClick}
                    className="brand-about-primary inline-flex items-center px-4 py-2 text-sm font-semibold rounded-lg transition-colors duration-200"
                >
                    Explore Ubundi
                </button>
            </div>

            {/* Footer - Compact */}
            <div className="brand-about-footer pt-2 border-t text-center">
                <p className="brand-about-muted text-xs">
                    Built for Ubundi
                </p>
            </div>
            {/* Update Dialog */}
            <UpdateDialog
                open={showUpdateDialog}
                onOpenChange={setShowUpdateDialog}
                updateInfo={updateInfo}
            />
        </div>

    )
}
