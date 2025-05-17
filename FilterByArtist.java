class FilterByArtist extends Filter {
    private Artist[] artist;
    public FilterByArtist(Artist... artist) {
        this.artist = artist;
    }
    public boolean accept(Song music) {
        for(int i=0;i<artist.length;i++){
            if(artist[i].getName().contains(music.getArtist().getName())){
                return true;
            }
        }
        return false;
    }
}
